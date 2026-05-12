import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:dio/dio.dart';

class DetailMarinas extends StatefulWidget {
  final Map marina;
  const DetailMarinas({super.key, required this.marina});

  @override
  State<DetailMarinas> createState() => _DetailMarinasState();
}

class _DetailMarinasState extends State<DetailMarinas>
    with SingleTickerProviderStateMixin {
  bool isFavourite = false;
  bool loading = false;
  bool bookingLoading = false;
  List berths = [];
  List filteredBerths = [];
  Position? userPosition;
  String? selectedBerthId;
  String searchQuery = '';
  DateTime? searchFrom;
  DateTime? searchTo;
  DateTime? fromDate;
  DateTime? toDate;
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  Map? bookingBerth;
  bool showBookingSheet = false;
  late ScrollController scrollController;
  double scrollOffset = 0;
  late AnimationController animController;
  late Animation<double> fadeAnim;
  final TextEditingController searchController = TextEditingController();

  double get w => MediaQuery.of(context).size.width;
  bool get isBig => w >= 600;
  double get hPad => isBig ? 32.0 : 24.0;
  double get heroH => isBig ? 440.0 : 380.0;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController()
      ..addListener(
        () => setState(() => scrollOffset = scrollController.offset),
      );
    animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );
    fadeAnim = CurvedAnimation(parent: animController, curve: Curves.easeOut);
    animController.forward();
    getUserLocation();
    loadBerths();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
        applySearch();
      });
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    animController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void applySearch() {
    if (searchQuery.isEmpty) {
      filteredBerths = berths;
    } else {
      filteredBerths = berths.where((b) {
        final name = (b['name'] ?? '').toString().toLowerCase();
        final desc = (b['description'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery) || desc.contains(searchQuery);
      }).toList();
    }
  }

  Future<void> getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;
      final pos = await Geolocator.getCurrentPosition();
      setState(() => userPosition = pos);
    } catch (_) {}
  }

  Future<void> loadBerths() async {
    setState(() => loading = true);
    try {
      final dio = await MyDio().getDio();
      String url = '/berths?marina_id=${widget.marina['id']}';
      if (searchFrom != null && searchTo != null) {
        url += '&from_date=${searchFrom!.toUtc().toIso8601String()}';
        url += '&to_date=${searchTo!.toUtc().toIso8601String()}';
      }
      final res = await dio.get(url);
      setState(() {
        berths = res.data['berths'] ?? [];
        applySearch();
      });
    } catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loading = false);
    }
  }

  double getDistanceKm() {
    if (userPosition == null) return -1;
    final meters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      widget.marina['latitude'],
      widget.marina['longitude'],
    );
    return meters / 1000;
  }

  String getDistanceLabel() {
    final km = getDistanceKm();
    if (km < 0) return 'Location unavailable';
    if (km < 0.5)
      return "You're practically here — ${(km * 1000).toStringAsFixed(0)}m away";
    if (km < 2)
      return '${km.toStringAsFixed(1)} km from you — a short sail away';
    if (km < 10) return '${km.toStringAsFixed(1)} km away — worth every wave';
    if (km < 50) return '${km.toStringAsFixed(0)} km from your position';
    return '${km.toStringAsFixed(0)} km away — plan your voyage';
  }

  String getDistanceShort() {
    final km = getDistanceKm();
    if (km < 0) return '—';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m';
    return '${km.toStringAsFixed(1)} km';
  }

  String formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime? combinedFrom() {
    if (fromDate == null || fromTime == null) return null;
    return DateTime(
      fromDate!.year,
      fromDate!.month,
      fromDate!.day,
      fromTime!.hour,
      fromTime!.minute,
    );
  }

  DateTime? combinedTo() {
    if (toDate == null || toTime == null) return null;
    return DateTime(
      toDate!.year,
      toDate!.month,
      toDate!.day,
      toTime!.hour,
      toTime!.minute,
    );
  }

  int get totalHours {
    final f = combinedFrom();
    final t = combinedTo();
    if (f == null || t == null) return 0;
    return t.difference(f).inHours;
  }

  double get totalPrice {
    if (bookingBerth == null || totalHours <= 0) return 0;
    if (totalHours < 24)
      return totalHours *
          ((bookingBerth!['price_per_hour'] ?? 100) as num).toDouble();
    final nights = totalHours ~/ 24;
    return nights *
        ((bookingBerth!['price_per_night'] ?? 750) as num).toDouble();
  }

  Future<void> pickDate(bool isFrom) async {
    final initial = isFrom
        ? DateTime.now().add(Duration(days: 1))
        : (fromDate ?? DateTime.now()).add(Duration(days: 1));
    final first = isFrom
        ? DateTime.now()
        : (fromDate ?? DateTime.now()).add(Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: Color(0xFFC9A84C),
            surface: Color(0xFF0D1B2A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null)
      setState(() {
        if (isFrom) {
          fromDate = picked;
          toDate = null;
          toTime = null;
        } else
          toDate = picked;
      });
  }

  Future<void> pickTime(bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: Color(0xFFC9A84C),
            surface: Color(0xFF0D1B2A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null)
      setState(() => isFrom ? fromTime = picked : toTime = picked);
  }

  Future<void> pickSearchDate(bool isFrom) async {
    final initial = isFrom
        ? DateTime.now().add(Duration(days: 1))
        : (searchFrom ?? DateTime.now()).add(Duration(days: 1));
    final first = isFrom
        ? DateTime.now()
        : (searchFrom ?? DateTime.now()).add(Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: Color(0xFFC9A84C),
            surface: Color(0xFF0D1B2A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          searchFrom = picked;
          searchTo = null;
        } else {
          searchTo = picked;
        }
      });
      if (!isFrom && picked != null) loadBerths();
    }
  }

  Future<void> submitBooking() async {
    final from = combinedFrom();
    final to = combinedTo();
    if (from == null || to == null || bookingBerth == null) return;
    setState(() => bookingLoading = true);
    try {
      final dio = await MyDio().getDio();
      await dio.post(
        '/bookings',
        data: {
          'berth_id': bookingBerth!['id'],
          'from_date': from.toUtc().toIso8601String(),
          'to_date': to.toUtc().toIso8601String(),
        },
      );
      if (!mounted) return;
      setState(() {
        showBookingSheet = false;
        fromDate = null;
        toDate = null;
        fromTime = null;
        toTime = null;
        bookingBerth = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Berth booked successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF2D7D4F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      loadBerths();
    } catch (e) {
      if (!mounted) return;
      String message = 'Booking failed';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map)
          message = data['message']?.toString() ?? message;
        else if (data is String)
          message = data;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Color(0xFF7D2D2D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() => bookingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final marina = widget.marina;
    final appBarCollapsed = scrollOffset > heroH - 120;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: Color(0xFF060E1A),
      body: Stack(
        children: [
          CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: heroH,
                pinned: true,
                stretch: true,
                backgroundColor: appBarCollapsed
                    ? Color(0xFF060E1A)
                    : Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/portImages/port.jpg',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 0.35, 0.75, 1.0],
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                              Color(0xFF060E1A).withOpacity(0.6),
                              Color(0xFF060E1A),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 32,
                        left: hPad,
                        right: hPad,
                        child: FadeTransition(
                          opacity: fadeAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2D7D4F),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Open for bookings',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  if (getDistanceKm() >= 0)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.white12,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.near_me_rounded,
                                            color: Color(0xFFC9A84C),
                                            size: 11,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            getDistanceShort(),
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                marina['name'] ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isBig ? 38 : 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                  height: 1.05,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFFC9A84C),
                                    size: 13,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    marina['location'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 14),
                                  Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFC9A84C),
                                    size: 13,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '4.8',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '(126)',
                                    style: TextStyle(
                                      color: Colors.white30,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: appBarCollapsed
                      ? Text(
                          marina['name'] ?? '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                leading: Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12, width: 0.5),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => setState(() => isFavourite = !isFavourite),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 250),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isFavourite
                              ? Color(0xFFC9A84C).withOpacity(0.2)
                              : Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFavourite
                                ? Color(0xFFC9A84C).withOpacity(0.5)
                                : Colors.white12,
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          isFavourite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavourite ? Color(0xFFC9A84C) : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: Color(0xFF0D1B2A),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              _statCell(
                                Icons.near_me_rounded,
                                getDistanceShort(),
                                'From you',
                              ),
                              _vDivider(),
                              _statCell(Icons.star_rounded, '4.8', 'Rating'),
                              _vDivider(),
                              _statCell(
                                Icons.anchor_rounded,
                                loading ? '—' : '${berths.length}',
                                'Berths',
                              ),
                              _vDivider(),
                              _statCell(
                                Icons.lock_open_rounded,
                                '24/7',
                                'Access',
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Distance narrative
                      if (getDistanceKm() >= 0)
                        Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Color(0xFFC9A84C).withOpacity(0.2),
                              ),
                              color: Color(0xFFC9A84C).withOpacity(0.05),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFC9A84C).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.sailing_rounded,
                                    color: Color(0xFFC9A84C),
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your distance',
                                        style: TextStyle(
                                          color: Color(0xFFC9A84C),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        getDistanceLabel(),
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // About
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('About this Marina'),
                            SizedBox(height: 10),
                            Text(
                              marina['description'] ??
                                  'A premium Norwegian marina offering world-class facilities in a breathtaking coastal setting.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: isBig ? 14.5 : 13.5,
                                height: 1.75,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Coordinates
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF0D1B2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.my_location_rounded,
                                color: Colors.white24,
                                size: 14,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${widget.marina['latitude']}°N  ${widget.marina['longitude']}°E',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Facilities
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 28, hPad, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Facilities'),
                            SizedBox(height: 16),
                            GridView.count(
                              crossAxisCount: isBig ? 5 : 4,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              children: [
                                _facility(Icons.bolt_rounded, 'Electric'),
                                _facility(Icons.water_drop_outlined, 'Water'),
                                _facility(Icons.wifi_rounded, 'Wi-Fi'),
                                _facility(Icons.shower_rounded, 'Showers'),
                                _facility(
                                  Icons.local_laundry_service_outlined,
                                  'Laundry',
                                ),
                                _facility(
                                  Icons.local_gas_station_outlined,
                                  'Fuel',
                                ),
                                _facility(
                                  Icons.restaurant_outlined,
                                  'Restaurant',
                                ),
                                _facility(Icons.security_rounded, 'Security'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Berths section
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 32, hPad, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _sectionTitle('Available Berths'),
                                if (!loading && berths.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(
                                        0xFFC9A84C,
                                      ).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Color(
                                          0xFFC9A84C,
                                        ).withOpacity(0.25),
                                      ),
                                    ),
                                    child: Text(
                                      '${filteredBerths.length} shown',
                                      style: TextStyle(
                                        color: Color(0xFFC9A84C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Date availability filter
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFF0D1B2A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.07),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event_available_rounded,
                                        color: Color(0xFFC9A84C),
                                        size: 14,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Check availability for your dates',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => pickSearchDate(true),
                                          child: Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF060E1A),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: searchFrom != null
                                                    ? Color(
                                                        0xFFC9A84C,
                                                      ).withOpacity(0.4)
                                                    : Colors.white12,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_rounded,
                                                  color: searchFrom != null
                                                      ? Color(0xFFC9A84C)
                                                      : Colors.white24,
                                                  size: 13,
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    searchFrom != null
                                                        ? formatDate(
                                                            searchFrom!,
                                                          )
                                                        : 'From date',
                                                    style: TextStyle(
                                                      color: searchFrom != null
                                                          ? Colors.white
                                                          : Colors.white30,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => pickSearchDate(false),
                                          child: Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF060E1A),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: searchTo != null
                                                    ? Color(
                                                        0xFFC9A84C,
                                                      ).withOpacity(0.4)
                                                    : Colors.white12,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_rounded,
                                                  color: searchTo != null
                                                      ? Color(0xFFC9A84C)
                                                      : Colors.white24,
                                                  size: 13,
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    searchTo != null
                                                        ? formatDate(searchTo!)
                                                        : 'To date',
                                                    style: TextStyle(
                                                      color: searchTo != null
                                                          ? Colors.white
                                                          : Colors.white30,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (searchFrom != null) ...[
                                        SizedBox(width: 10),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              searchFrom = null;
                                              searchTo = null;
                                            });
                                            loadBerths();
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF060E1A),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.white12,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.close_rounded,
                                              color: Colors.white38,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  if (searchFrom == null)
                                    Text(
                                      'Pick dates to see which berths are free for your trip',
                                      style: TextStyle(
                                        color: Colors.white24,
                                        fontSize: 11,
                                      ),
                                    ),
                                  if (searchFrom != null && searchTo == null)
                                    Text(
                                      'Now pick your end date to check availability',
                                      style: TextStyle(
                                        color: Color(0xFFC9A84C),
                                        fontSize: 11,
                                      ),
                                    ),
                                  if (searchFrom != null && searchTo != null)
                                    Text(
                                      'Showing availability: ${formatDate(searchFrom!)} → ${formatDate(searchTo!)}',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 14),

                            // Search bar
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF0D1B2A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.07),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(width: 16),
                                  Icon(
                                    Icons.search_rounded,
                                    color: Colors.white30,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: searchController,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search berths by name...',
                                        hintStyle: TextStyle(
                                          color: Colors.white24,
                                          fontSize: 13,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        searchController.clear();
                                        setState(() {
                                          searchQuery = '';
                                          filteredBerths = berths;
                                        });
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 12),
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: Colors.white30,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Berths list
              loading
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFC9A84C),
                            strokeWidth: 1.5,
                          ),
                        ),
                      ),
                    )
                  : filteredBerths.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                searchQuery.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.anchor,
                                color: Colors.white10,
                                size: 52,
                              ),
                              SizedBox(height: 14),
                              Text(
                                searchQuery.isNotEmpty
                                    ? 'No berths match "$searchQuery"'
                                    : 'No berths available',
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 130),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final berth = filteredBerths[index];
                          final isBooked = berth['is_available'] == false;
                          final bookedFrom = berth['booked_from'];
                          final bookedTo = berth['booked_to'];
                          String bookedLabel = 'Currently unavailable';
                          if (bookedFrom != null && bookedTo != null) {
                            final from = DateTime.parse(bookedFrom).toLocal();
                            final to = DateTime.parse(bookedTo).toLocal();
                            bookedLabel =
                                'Booked: ${formatDate(from)} → ${formatDate(to)}';
                          }

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 300 + index * 80),
                            curve: Curves.easeOutCubic,
                            builder: (context, val, child) => Opacity(
                              opacity: val,
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - val)),
                                child: child,
                              ),
                            ),
                            child: Container(
                              margin: EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Color(0xFF0D1B2A),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isBooked
                                      ? Colors.white.withOpacity(0.04)
                                      : Colors.white.withOpacity(0.07),
                                  width: 0.5,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(isBig ? 20 : 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: isBooked
                                                ? Colors.white.withOpacity(0.04)
                                                : Color(
                                                    0xFFC9A84C,
                                                  ).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: isBooked
                                                  ? Colors.white12
                                                  : Color(
                                                      0xFFC9A84C,
                                                    ).withOpacity(0.18),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.anchor_rounded,
                                            color: isBooked
                                                ? Colors.white24
                                                : Color(0xFFC9A84C),
                                            size: 22,
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      berth['name'] ?? 'Berth',
                                                      style: TextStyle(
                                                        color: isBooked
                                                            ? Colors.white38
                                                            : Colors.white,
                                                        fontSize: isBig
                                                            ? 16
                                                            : 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isBooked)
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Color(
                                                          0xFF7D2D2D,
                                                        ).withOpacity(0.3),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                        border: Border.all(
                                                          color: Color(
                                                            0xFF7D2D2D,
                                                          ).withOpacity(0.5),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Booked',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFFE57373,
                                                          ),
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                berth['description'] ??
                                                    'Standard berth',
                                                style: TextStyle(
                                                  color: isBooked
                                                      ? Colors.white24
                                                      : Colors.white38,
                                                  fontSize: 12,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 14),
                                    Row(
                                      children: [
                                        _berthTag(
                                          Icons.straighten_rounded,
                                          'Up to ${berth['length'] ?? 12}m',
                                        ),
                                        SizedBox(width: 8),
                                        _berthTag(
                                          Icons.waves_rounded,
                                          'Beam ${berth['width'] ?? 4}m',
                                        ),
                                        Spacer(),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${berth['price_per_night'] ?? 750}',
                                                style: TextStyle(
                                                  color: isBooked
                                                      ? Colors.white24
                                                      : Colors.white,
                                                  fontSize: isBig ? 20 : 18,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              TextSpan(
                                                text: ' NOK/night',
                                                style: TextStyle(
                                                  color: Colors.white30,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Booked date range info
                                    if (isBooked) ...[
                                      SizedBox(height: 12),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(
                                            0xFF7D2D2D,
                                          ).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Color(
                                              0xFF7D2D2D,
                                            ).withOpacity(0.25),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.block_rounded,
                                              color: Color(0xFFE57373),
                                              size: 14,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                bookedLabel,
                                                style: TextStyle(
                                                  color: Color(0xFFE57373),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.info_outline_rounded,
                                              color: Colors.white24,
                                              size: 13,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Try different dates to check availability',
                                              style: TextStyle(
                                                color: Colors.white24,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Available buttons
                                    if (!isBooked) ...[
                                      SizedBox(height: 14),
                                      Container(
                                        height: 0.5,
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                      SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () =>
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .construction_rounded,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                          SizedBox(width: 10),
                                                          Text(
                                                            'Berth detail page coming soon',
                                                          ),
                                                        ],
                                                      ),
                                                      backgroundColor: Color(
                                                        0xFF1A2A3A,
                                                      ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 13,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.12),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.visibility_outlined,
                                                      color: Colors.white60,
                                                      size: 15,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'View',
                                                      style: TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            flex: 2,
                                            child: GestureDetector(
                                              onTap: () => setState(() {
                                                bookingBerth = berth;
                                                selectedBerthId = berth['id'];
                                                showBookingSheet = true;
                                              }),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 13,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFC9A84C),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.anchor_rounded,
                                                      color: Colors.black,
                                                      size: 15,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Book',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }, childCount: filteredBerths.length),
                      ),
                    ),
            ],
          ),

          // Booking sheet backdrop
          if (showBookingSheet)
            GestureDetector(
              onTap: () => setState(() => showBookingSheet = false),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),

          // Booking sheet
          if (showBookingSheet)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF0D1B2A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  padding: EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFFC9A84C).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.anchor_rounded,
                              color: Color(0xFFC9A84C),
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookingBerth?['name'] ?? 'Berth',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${bookingBerth?['price_per_night'] ?? 750} NOK/night  •  ${bookingBerth?['price_per_hour'] ?? 100} NOK/hour',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => showBookingSheet = false),
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white38,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 22),

                      Text(
                        'Check-in',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () => pickDate(true),
                              child: Container(
                                padding: EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Color(0xFF060E1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: fromDate != null
                                        ? Color(0xFFC9A84C).withOpacity(0.4)
                                        : Colors.white12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: fromDate != null
                                          ? Color(0xFFC9A84C)
                                          : Colors.white24,
                                      size: 14,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      fromDate != null
                                          ? formatDate(fromDate!)
                                          : 'Date',
                                      style: TextStyle(
                                        color: fromDate != null
                                            ? Colors.white
                                            : Colors.white30,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => pickTime(true),
                              child: Container(
                                padding: EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Color(0xFF060E1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: fromTime != null
                                        ? Color(0xFFC9A84C).withOpacity(0.4)
                                        : Colors.white12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      color: fromTime != null
                                          ? Color(0xFFC9A84C)
                                          : Colors.white24,
                                      size: 14,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      fromTime != null
                                          ? formatTime(fromTime!)
                                          : 'Time',
                                      style: TextStyle(
                                        color: fromTime != null
                                            ? Colors.white
                                            : Colors.white30,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 14),
                      Text(
                        'Check-out',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () => pickDate(false),
                              child: Container(
                                padding: EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Color(0xFF060E1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: toDate != null
                                        ? Color(0xFFC9A84C).withOpacity(0.4)
                                        : Colors.white12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      color: toDate != null
                                          ? Color(0xFFC9A84C)
                                          : Colors.white24,
                                      size: 14,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      toDate != null
                                          ? formatDate(toDate!)
                                          : 'Date',
                                      style: TextStyle(
                                        color: toDate != null
                                            ? Colors.white
                                            : Colors.white30,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => pickTime(false),
                              child: Container(
                                padding: EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Color(0xFF060E1A),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: toTime != null
                                        ? Color(0xFFC9A84C).withOpacity(0.4)
                                        : Colors.white12,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      color: toTime != null
                                          ? Color(0xFFC9A84C)
                                          : Colors.white24,
                                      size: 14,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      toTime != null
                                          ? formatTime(toTime!)
                                          : 'Time',
                                      style: TextStyle(
                                        color: toTime != null
                                            ? Colors.white
                                            : Colors.white30,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (totalHours > 0) ...[
                        SizedBox(height: 18),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF060E1A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Duration',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    totalHours < 24
                                        ? '$totalHours hour${totalHours > 1 ? 's' : ''}'
                                        : '${totalHours ~/ 24} night${totalHours ~/ 24 > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Container(height: 0.5, color: Colors.white10),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${totalPrice.toStringAsFixed(0)} NOK',
                                    style: TextStyle(
                                      color: Color(0xFFC9A84C),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 20),
                      GestureDetector(
                        onTap:
                            combinedFrom() != null &&
                                combinedTo() != null &&
                                !bookingLoading
                            ? submitBooking
                            : null,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color:
                                combinedFrom() != null && combinedTo() != null
                                ? Color(0xFFC9A84C)
                                : Colors.white12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: bookingLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Confirm Booking',
                                    style: TextStyle(
                                      color:
                                          combinedFrom() != null &&
                                              combinedTo() != null
                                          ? Colors.black
                                          : Colors.white24,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: TextStyle(
      color: Colors.white,
      fontSize: isBig ? 20 : 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
  );

  Widget _statCell(IconData icon, String value, String label) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: Color(0xFFC9A84C), size: 16),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isBig ? 15 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white30,
            fontSize: 10,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );

  Widget _vDivider() =>
      Container(width: 0.5, height: 36, color: Colors.white10);

  Widget _facility(IconData icon, String label) => Container(
    decoration: BoxDecoration(
      color: Color(0xFF0D1B2A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.5),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Color(0xFFC9A84C), size: isBig ? 22 : 20),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _berthTag(IconData icon, String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white30, size: 11),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

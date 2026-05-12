import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/screens/bookings/manageBookingScren.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  List<dynamic> bookingsData = [];
  List<dynamic> filteredBookings = [];
  late TabController tabController;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    loadMyBookings();
    searchController.addListener(onSearch);
  }

  @override
  void dispose() {
    tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  String marinaName(dynamic booking) => booking['marina']?['name'] ?? '';
  String berthName(dynamic booking) => booking['berth']?['name'] ?? '';

  void onSearch() {
    setState(() {
      final query = searchController.text.toLowerCase();
      filteredBookings = bookingsData
          .where(
            (b) =>
                marinaName(b).toLowerCase().contains(query) ||
                berthName(b).toLowerCase().contains(query),
          )
          .toList();
    });
  }

  Future<void> loadMyBookings() async {
    setState(() => isLoading = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/bookings/my');
      setState(() {
        bookingsData = res.data['bookings'] ?? [];
        filteredBookings = bookingsData;
      });
    } on DioException catch (e) {
      dioErrorManager(e);
      debugPrint('Bookings error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> checkIn(String bookingId) async {
    try {
      final dio = await MyDio().getDio();
      await dio.patch('/bookings/$bookingId/checkin');
      await loadMyBookings();
      if (!mounted) return;
      tabController.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checked in! Your booking is now ongoing.'),
          backgroundColor: Color(0xFF2D7D4F),
        ),
      );
    } on DioException catch (e) {
      dioErrorManager(e);
    }
  }

  Future<void> checkOut(String bookingId) async {
    try {
      final dio = await MyDio().getDio();
      await dio.patch('/bookings/$bookingId/checkout');
      await loadMyBookings();
      if (!mounted) return;
      tabController.animateTo(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checked out! Hope you enjoyed your stay.'),
          backgroundColor: Color(0xFF1A4A6B),
        ),
      );
    } on DioException catch (e) {
      dioErrorManager(e);
    }
  }

  // upcoming = confirmed and from_date is in the future
  List<dynamic> get upcomingBookings => filteredBookings.where((b) {
    if (b['status'] != 'confirmed') return false;
    final from = DateTime.parse(b['from_date']).toLocal();
    return from.isAfter(DateTime.now());
  }).toList();

  // ongoing = confirmed time range is now OR checked_in
  List<dynamic> get ongoingBookings => filteredBookings.where((b) {
    if (b['status'] == 'checked_in') return true;
    if (b['status'] == 'confirmed') {
      final now = DateTime.now();
      final from = DateTime.parse(b['from_date']).toLocal();
      final to = DateTime.parse(b['to_date']).toLocal();
      return !from.isAfter(now) && !to.isBefore(now);
    }
    return false;
  }).toList();

  // past = completed or cancelled (explicit status, not time based)
  List<dynamic> get pastBookings => filteredBookings.where((b) {
    return b['status'] == 'completed' || b['status'] == 'cancelled';
  }).toList();

  String formatDateTime(String dateStr) {
    final date = DateTime.parse(dateStr).toLocal();
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
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]}, $hour:$minute $period';
  }

  String formatDuration(String from, String to) {
    final diff = DateTime.parse(to).difference(DateTime.parse(from));
    final totalHours = diff.inMinutes / 60;
    if (totalHours < 24) {
      final h = diff.inHours;
      return h == 1 ? '1 hour' : '$h hours';
    }
    final days = diff.inDays;
    final remainingHours = diff.inHours - days * 24;
    if (remainingHours == 0) return days == 1 ? '1 night' : '$days nights';
    return '$days nights, ${remainingHours}h';
  }

  // fixed — explicit color for every status
  Color statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Color(0xFF2D7D4F);
      case 'checked_in':
        return Color(0xFF1A6B4A);
      case 'completed':
        return Color(0xFF1A4A6B);
      case 'cancelled':
        return Color(0xFF7D2D2D);
      default:
        return Color(0xFF4A4A4A);
    }
  }

  // fixed — explicit label for every status
  String statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
        return 'Checked In';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool isTabletOrUp(double w) => w >= 600;

  double maxContentWidth(double w) {
    if (w >= 1000) return 900;
    if (w >= 600) return 720;
    return w;
  }

  Widget buildStatusPill(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget buildStatCell(IconData icon, String label, String value, bool isBig) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white38, size: isBig ? 14 : 13),
                SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: isBig ? 12 : 11,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: isBig ? 13.5 : 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    bool outlined = false,
    bool isBig = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isBig ? 14 : 12),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            border: outlined ? Border.all(color: color, width: 1) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: isBig ? 14 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCard(dynamic booking, bool isBig) {
    final status = booking['status'] as String;
    final duration = formatDuration(booking['from_date'], booking['to_date']);
    final imageWidth = isBig ? 200.0 : 120.0;
    final imageHeight = isBig ? 200.0 : 170.0;
    final bookingId = booking['id'] as String;

    // check if check-in is allowed (within 1 hour before from_date)
    final from = DateTime.parse(booking['from_date']).toLocal();
    final now = DateTime.now();
    final diffHours = from.difference(now).inMinutes / 60;
    final canCheckIn =
        status == 'confirmed' &&
        diffHours <= 1 &&
        from.isAfter(now.subtract(Duration(hours: 24)));

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF131E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/portImages/port.jpg',
                        width: imageWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: buildStatusPill(
                          statusLabel(status),
                          statusColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isBig ? 18 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                marinaName(booking),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isBig ? 18 : 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white24,
                              size: 13,
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.white38,
                              size: 13,
                            ),
                            SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                berthName(booking),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: isBig ? 13 : 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isBig ? 16 : 10),
                        Text(
                          'Check-in',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: isBig ? 12 : 11,
                          ),
                        ),
                        Text(
                          formatDateTime(booking['from_date']),
                          style: TextStyle(
                            color: Color(0xFFC9A84C),
                            fontSize: isBig ? 14 : 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: isBig ? 10 : 6),
                        Text(
                          'Check-out',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: isBig ? 12 : 11,
                          ),
                        ),
                        Text(
                          formatDateTime(booking['to_date']),
                          style: TextStyle(
                            color: Color(0xFFC9A84C),
                            fontSize: isBig ? 14 : 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isBig ? 18 : 14,
              vertical: isBig ? 14 : 12,
            ),
            child: Row(
              children: [
                buildStatCell(Icons.anchor, 'Berth', berthName(booking), isBig),
                Container(width: 0.5, height: 32, color: Color(0xFF243044)),
                buildStatCell(Icons.access_time, 'Duration', duration, isBig),
                Container(width: 0.5, height: 32, color: Color(0xFF243044)),
                buildStatCell(
                  Icons.credit_card_outlined,
                  'Total',
                  '${booking['total_price']} NOK',
                  isBig,
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              isBig ? 18 : 14,
              0,
              isBig ? 18 : 14,
              isBig ? 18 : 14,
            ),
            child: Row(
              children: [
                // buildActionButton(
                //   label: 'View details',
                //   color: Color(0xFFC9A84C),
                //   textColor: Color(0xFFC9A84C),
                //   outlined: true,
                //   isBig: isBig,
                //   onTap: () {},
                // ),

                // confirmed + upcoming → manage booking
                if (status == 'confirmed' && from.isAfter(now)) ...[
                  SizedBox(width: 10),
                  buildActionButton(
                    label: 'View Details',
                    color: Color(0xFFC9A84C),
                    textColor: Colors.black,
                    isBig: isBig,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ManageBookingScreen(booking: booking),
                        ),
                      );
                      if (result == 'refresh') loadMyBookings();
                    },
                  ),
                ],

                // confirmed + within 1 hour window → check in
                if (canCheckIn) ...[
                  SizedBox(width: 10),
                  buildActionButton(
                    label: 'Check In',
                    color: Color(0xFF2D7D4F),
                    textColor: Colors.white,
                    isBig: isBig,
                    onTap: () => checkIn(bookingId),
                  ),
                ],

                // checked_in → check out
                if (status == 'checked_in') ...[
                  SizedBox(width: 10),
                  buildActionButton(
                    label: 'Check Out',
                    color: Color(0xFF1A4A6B),
                    textColor: Colors.white,
                    isBig: isBig,
                    onTap: () => checkOut(bookingId),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildList(
    List<dynamic> bookings,
    double hPad,
    double sectionTitleSize,
    double bodySize,
    bool isBig, {
    required String emptyText,
    required String listTitle,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.anchor, color: Colors.white12, size: isBig ? 72 : 56),
            SizedBox(height: 16),
            Text(
              emptyText,
              style: TextStyle(
                color: Colors.white38,
                fontSize: isBig ? 16 : 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              listTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: sectionTitleSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${bookings.length} bookings',
              style: TextStyle(color: Color(0xFFC9A84C), fontSize: bodySize),
            ),
          ],
        ),
        SizedBox(height: isBig ? 16 : 14),
        ...bookings.map(
          (b) => Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: buildCard(b, isBig),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isBig = isTabletOrUp(width);
    final hPad = isBig ? 28.0 : 20.0;
    final titleSize = isBig ? 32.0 : 26.0;
    final subtitleSize = isBig ? 13.0 : 12.0;
    final sectionTitleSize = isBig ? 19.0 : 16.5;
    final bodySize = isBig ? 13.0 : 12.0;
    final tabFontSize = isBig ? 14.0 : 12.5;

    return Scaffold(
      backgroundColor: Color(0xFF0A1628),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF0A1628),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF1A2A3A), width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'My ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Bookings',
                                    style: TextStyle(
                                      color: Color(0xFFC9A84C),
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${bookingsData.length} total reservations',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: subtitleSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF131E2E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFF243044),
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: isBig ? 24 : 22,
                            ),
                          ),
                          if (upcomingBookings.isNotEmpty)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Color(0xFFC9A84C),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${upcomingBookings.length}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: isBig ? 14 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF131E2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF243044), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.white38, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: bodySize,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search marina or berth...',
                              hintStyle: TextStyle(
                                color: Colors.white38,
                                fontSize: bodySize,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Container(
                    height: isBig ? 48 : 42,
                    decoration: BoxDecoration(
                      color: Color(0xFF131E2E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      controller: tabController,
                      indicator: BoxDecoration(
                        color: Color(0xFFC9A84C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: TextStyle(
                        fontSize: tabFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(fontSize: tabFontSize),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: 'Upcoming'),
                        Tab(text: 'Ongoing'),
                        Tab(text: 'Past'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFC9A84C),
                          ),
                        )
                      : TabBarView(
                          controller: tabController,
                          children: [
                            buildList(
                              upcomingBookings,
                              hPad,
                              sectionTitleSize,
                              bodySize,
                              isBig,
                              emptyText: 'No upcoming bookings',
                              listTitle: 'Upcoming bookings',
                            ),
                            buildList(
                              ongoingBookings,
                              hPad,
                              sectionTitleSize,
                              bodySize,
                              isBig,
                              emptyText: 'No ongoing bookings',
                              listTitle: 'Ongoing bookings',
                            ),
                            buildList(
                              pastBookings,
                              hPad,
                              sectionTitleSize,
                              bodySize,
                              isBig,
                              emptyText: 'No past bookings',
                              listTitle: 'Past bookings',
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/provider/userProvider.dart';
import 'package:marinahub/screens/explore/detailExplore.dart';
import 'package:marinahub/screens/explore/exploreScreen.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = false;
  List marinas = [];
  List allMarinas = [];
  List filteredMarinas = [];
  Position? userPosition;
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;

  double get w => MediaQuery.of(context).size.width;
  bool get isTablet => w >= 600 && w < 1000;
  bool get isDesktop => w >= 1000;
  bool get isTabletOrUp => w >= 600;
  int get cols => isDesktop
      ? 3
      : isTablet
      ? 2
      : 1;
  double get hPad => isDesktop
      ? 32
      : isTablet
      ? 28
      : 20;
  double get maxW => isDesktop
      ? 1200
      : isTablet
      ? 900
      : w;
  double get heroH => isDesktop
      ? 360
      : isTablet
      ? 320
      : 280;

  @override
  void initState() {
    super.initState();
    initLocationAndMarinas();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredMarinas = marinas; // back to top 2
        isSearching = false;
      } else {
        isSearching = true;
        filteredMarinas = allMarinas.where((m) {
          // search ALL
          final name = (m['name'] ?? '').toLowerCase();
          final location = (m['location'] ?? '').toLowerCase();
          return name.contains(query) || location.contains(query);
        }).toList();
      }
    });
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12)
      return "Good morning,";
    else if (hour < 17)
      return "Good afternoon,";
    else if (hour < 21)
      return "Good evening,";
    else
      return "Good night,";
  }

  Future<void> initLocationAndMarinas() async {
    await requestLocation();
    await loadMarinas();
  }

  Future<void> requestLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    userPosition = await Geolocator.getCurrentPosition();
  }

  Future<void> loadMarinas() async {
    setState(() => loading = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/marinas');
      List fetched = res.data['marinas'];
      if (userPosition != null) {
        fetched.sort((a, b) {
          final distA = Geolocator.distanceBetween(
            userPosition!.latitude,
            userPosition!.longitude,
            a['latitude'],
            a['longitude'],
          );
          final distB = Geolocator.distanceBetween(
            userPosition!.latitude,
            userPosition!.longitude,
            b['latitude'],
            b['longitude'],
          );
          return distA.compareTo(distB);
        });
      }
      setState(() {
        allMarinas = fetched; // full list
        marinas = fetched.take(2).toList(); // top 2 nearby
        filteredMarinas = marinas;
      });
    } catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loading = false);
    }
  }

  String getDistance(Map marina) {
    if (userPosition == null) return marina['location'] ?? '';
    final meters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      marina['latitude'],
      marina['longitude'],
    );
    final distStr = meters < 1000
        ? '${meters.toStringAsFixed(0)} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
    return '${marina['location']} • $distStr away';
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    return Scaffold(
      backgroundColor: Color(0xFF1A2232),
      body: loading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C)))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          SizedBox(
                            height: heroH,
                            width: double.infinity,
                            child: Image.asset(
                              'assets/images/portImages/port.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            height: heroH,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Color(0xFF1A2232),
                                ],
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: hPad),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.anchor,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'MARINAHUB',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: isTabletOrUp ? 18 : 16,
                                              letterSpacing: 3,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Stack(
                                        children: [
                                          Icon(
                                            Icons.notifications_outlined,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFC9A84C),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '3',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isTabletOrUp ? 32 : 24),
                                  Text(
                                    getGreeting(),
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isTabletOrUp ? 16 : 14,
                                    ),
                                  ),
                                  Text(
                                    userProvider.userData?["name"] ?? "Captain",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTabletOrUp ? 40 : 30,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Where will the tide take you today?',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: isTabletOrUp ? 15 : 13,
                                    ),
                                  ),
                                  SizedBox(height: isTabletOrUp ? 28 : 20),
                                  // SEARCH BAR
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: isTabletOrUp ? 4 : 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.search,
                                                color: Colors.grey,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: TextField(
                                                  controller: _searchController,
                                                  style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: isTabletOrUp
                                                        ? 14
                                                        : 13,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Search marina, location or region',
                                                    hintStyle: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: isTabletOrUp
                                                          ? 14
                                                          : 13,
                                                    ),
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          vertical: isTabletOrUp
                                                              ? 14
                                                              : 12,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              if (_searchController
                                                  .text
                                                  .isNotEmpty)
                                                GestureDetector(
                                                  onTap: () {
                                                    _searchController.clear();
                                                  },
                                                  child: Icon(
                                                    Icons.clear,
                                                    color: Colors.grey,
                                                    size: 18,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Container(
                                        padding: EdgeInsets.all(
                                          isTabletOrUp ? 16 : 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF243044),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.tune,
                                          color: Colors.white,
                                          size: 20,
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
                    ),

                    // SEARCH RESULTS HEADER or NEARBY MARINAS header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isSearching
                                  ? '${filteredMarinas.length} result${filteredMarinas.length == 1 ? '' : 's'} found'
                                  : 'Nearby Marinas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTabletOrUp ? 20 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!isSearching)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => exploreScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFC9A84C,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFC9A84C,
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'ALL MARINAS',
                                        style: TextStyle(
                                          color: Color(0xFFC9A84C),
                                          fontSize: isTabletOrUp ? 14 : 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Color(0xFFC9A84C),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // NO RESULTS
                    if (isSearching && filteredMarinas.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: hPad,
                            vertical: 40,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.anchor,
                                color: Colors.white24,
                                size: 48,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No marinas found',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Try a different name or location',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // MARINA GRID
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: cols == 1
                              ? (w / 320)
                              : cols == 2
                              ? 1.4
                              : 1.25,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final marina = filteredMarinas[index];
                          final isAvailable = index % 2 == 0;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailMarinas(marina: marina),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF243044),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                          child: Image.asset(
                                            index % 2 == 0
                                                ? 'assets/images/portImages/port.jpg'
                                                : 'assets/images/portImages/port2.png',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isAvailable
                                                  ? Color(0xFF2D7D4F)
                                                  : Color(0xFFC4793A),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.anchor,
                                                  color: Colors.white38,
                                                  size: 13,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '${marina['totalBerths'] ?? 0} berth${(marina['totalBerths'] ?? 0) == 1 ? '' : 's'}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
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
                                    padding: EdgeInsets.all(14),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                marina['name'] ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isTabletOrUp
                                                      ? 16
                                                      : 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
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
                                                      getDistance(marina),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white38,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'From',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 11,
                                              ),
                                            ),
                                            Text(
                                              marina['cheapestPrice'] != null
                                                  ? '${marina['cheapestPrice']} NOK'
                                                  : 'N/A',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: isTabletOrUp
                                                    ? 16
                                                    : 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }, childCount: filteredMarinas.length),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ),
    );
  }
}

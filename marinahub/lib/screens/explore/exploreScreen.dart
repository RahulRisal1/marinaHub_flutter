import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/screens/explore/detailMarinas.dart';

class exploreScreen extends StatefulWidget {
  const exploreScreen({super.key});

  @override
  State<exploreScreen> createState() => _exploreScreenState();
}

class _exploreScreenState extends State<exploreScreen> {
  bool loading = false;
  List marinas = [];
  List filteredMarinas = [];
  int selectedFilter = 0;
  String searchQuery = '';
  Position? userPosition;

  List<String> filters = ['All', 'Nearby', 'Has Berths', 'A → Z'];

  List<double> ratings = [4.8, 4.7, 4.6, 4.5, 4.9];
  List<int> reviews = [126, 89, 72, 54, 143];

  double get w => MediaQuery.of(context).size.width;
  bool get isBig => w >= 600;
  bool get isDesktop => w >= 1000;
  double get hPad => isBig ? 28.0 : 20.0;
  double get maxW => isDesktop
      ? 1200
      : isBig
      ? 900
      : w;
  int get cols => isDesktop
      ? 3
      : isBig
      ? 2
      : 1;

  double get titleSize => isBig ? 32.0 : 26.0;
  double get subtitleSize => isBig ? 14.0 : 12.0;
  double get sectionTitleSize => isBig ? 20.0 : 17.0;
  double get cardTitleSize => isBig ? 16.0 : 14.5;
  double get bodySize => isBig ? 13.0 : 11.5;
  double get smallSize => isBig ? 12.0 : 11.0;
  double get priceSize => isBig ? 17.0 : 14.5;

  @override
  void initState() {
    super.initState();
    initLocationAndMarinas();
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
      setState(() {
        marinas = res.data['marinas'];
        applyFilter();
      });
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loading = false);
    }
  }

  double getDistanceInKm(Map marina) {
    if (userPosition == null) return double.infinity;
    final meters = Geolocator.distanceBetween(
      userPosition!.latitude,
      userPosition!.longitude,
      marina['latitude'],
      marina['longitude'],
    );
    return meters / 1000;
  }

  String getDistanceLabel(Map marina) {
    if (userPosition == null) return marina['location'] ?? '';
    final km = getDistanceInKm(marina);
    final distStr = km < 1
        ? '${(km * 1000).toStringAsFixed(0)} m'
        : '${km.toStringAsFixed(1)} km';
    return '${marina['location']} • $distStr away';
  }

  void applyFilter() {
    List result = marinas.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      final location = (m['location'] ?? '').toString().toLowerCase();
      return searchQuery.isEmpty ||
          name.contains(searchQuery.toLowerCase()) ||
          location.contains(searchQuery.toLowerCase());
    }).toList();

    if (selectedFilter == 1) {
      result.sort((a, b) => getDistanceInKm(a).compareTo(getDistanceInKm(b)));
      result = result.where((m) => getDistanceInKm(m) <= 50).toList();
    } else if (selectedFilter == 2) {
      result = result
          .where((m) => ((m['totalBerths'] ?? 0) as num) > 0)
          .toList();
    } else if (selectedFilter == 3) {
      result.sort(
        (a, b) => (a['name'] ?? '').toString().compareTo(
          (b['name'] ?? '').toString(),
        ),
      );
    }

    setState(() => filteredMarinas = result);
  }

  void onFilterTap(int index) {
    setState(() => selectedFilter = index);
    applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.transparent,

        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFFC9A84C),
              size: 16,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {}, // add map action here if needed
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A3A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFC9A84C).withOpacity(0.4),
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.map_outlined,
                color: const Color(0xFFC9A84C),
                size: isBig ? 24 : 22,
              ),
            ),
          ),
        ],
        title: Text(
          "Explore Marinas",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C)))
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: CustomScrollView(
                    slivers: [
                      // SliverToBoxAdapter(
                      //   child: Padding(
                      //     padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: [
                      //         Expanded(
                      //           child: Column(
                      //             crossAxisAlignment: CrossAxisAlignment.start,
                      //             children: [
                      //               RichText(
                      //                 text: TextSpan(
                      //                   children: [
                      //                     TextSpan(
                      //                       text: 'Explore ',
                      //                       style: TextStyle(
                      //                         color: Colors.white,
                      //                         fontSize: titleSize,
                      //                         fontWeight: FontWeight.w600,
                      //                       ),
                      //                     ),
                      //                     TextSpan(
                      //                       text: 'Marinas',
                      //                       style: TextStyle(
                      //                         color: Color(0xFFC9A84C),
                      //                         fontSize: titleSize,
                      //                         fontWeight: FontWeight.w600,
                      //                       ),
                      //                     ),
                      //                   ],
                      //                 ),
                      //               ),
                      //               SizedBox(height: 4),
                      //               Text(
                      //                 'Discover premium marinas across Norway',
                      //                 style: TextStyle(
                      //                   color: Colors.white38,
                      //                   fontSize: subtitleSize,
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         ),
                      //         SizedBox(width: 12),
                      //         Container(
                      //           padding: EdgeInsets.all(12),
                      //           decoration: BoxDecoration(
                      //             color: Color(0xFF1A2A3A),
                      //             borderRadius: BorderRadius.circular(10),
                      //             border: Border.all(
                      //               color: Color(0xFFC9A84C).withOpacity(0.4),
                      //               width: 0.8,
                      //             ),
                      //           ),
                      //           child: Icon(
                      //             Icons.map_outlined,
                      //             color: Color(0xFFC9A84C),
                      //             size: isBig ? 24 : 22,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                          child: TextField(
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: bodySize,
                            ),
                            onChanged: (val) {
                              searchQuery = val;
                              applyFilter();
                            },
                            decoration: InputDecoration(
                              hintText: 'Search marina, location or region',
                              hintStyle: TextStyle(
                                color: Colors.white38,
                                fontSize: bodySize,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white38,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: Color(0xFF1A2A3A),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: isBig ? 16 : 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(filters.length, (i) {
                                final selected = selectedFilter == i;
                                final icons = [
                                  Icons.grid_view_rounded,
                                  Icons.location_on_outlined,
                                  Icons.anchor,
                                  Icons.sort_by_alpha,
                                ];
                                return GestureDetector(
                                  onTap: () => onFilterTap(i),
                                  child: Container(
                                    margin: EdgeInsets.only(right: 10),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isBig ? 12 : 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Color(0xFFC9A84C)
                                          : Color(0xFF1A2A3A),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          icons[i],
                                          color: selected
                                              ? Colors.black
                                              : Colors.white38,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          filters[i],
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.black
                                                : Colors.white60,
                                            fontSize: bodySize,
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 0),
                          child: AspectRatio(
                            aspectRatio: isBig ? 3.2 : 2.2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    'assets/images/portImages/port.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.65),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(isBig ? 24 : 18),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Summer in Norway',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isBig ? 24 : 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Explore breathtaking destinations\nfor your next voyage',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: bodySize,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              'Explore now',
                                              style: TextStyle(
                                                color: Color(0xFFC9A84C),
                                                fontSize: bodySize,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Color(0xFFC9A84C),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filteredMarinas.length} Marinas found',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: sectionTitleSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      filteredMarinas.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 60),
                                child: Center(
                                  child: Text(
                                    selectedFilter == 1
                                        ? 'No marinas within 50 km'
                                        : selectedFilter == 2
                                        ? 'No marinas with available berths'
                                        : 'No marinas found',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: bodySize,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: EdgeInsets.symmetric(horizontal: hPad),
                              sliver: SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      mainAxisExtent: isBig ? 140 : 120,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final marina = filteredMarinas[index];
                                  // final isAvailable = index % 2 == 0;
                                  final rating =
                                      ratings[index % ratings.length];
                                  final review =
                                      reviews[index % reviews.length];

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
                                        color: Color(0xFF1A2A3A),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 1,
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(12),
                                                        bottomLeft:
                                                            Radius.circular(12),
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
                                                  top: 8,
                                                  left: 8,
                                                  child: Icon(
                                                    Icons.favorite_border,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                12,
                                                10,
                                                12,
                                                10,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          marina['name'] ?? '',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize:
                                                                cardTitleSize,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 6),
                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 5,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Color(
                                                            0xFF2D7D4F,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.anchor,
                                                              color: Colors
                                                                  .white38,
                                                              size: 13,
                                                            ),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              '${marina['totalBerths'] ?? 0} berth${(marina['totalBerths'] ?? 0) == 1 ? '' : 's'}',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        color: Color(
                                                          0xFFC9A84C,
                                                        ),
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        '$rating ($review)',
                                                        style: TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: smallSize,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .location_on_outlined,
                                                        color: Colors.white38,
                                                        size: 13,
                                                      ),
                                                      SizedBox(width: 3),
                                                      Expanded(
                                                        child: Text(
                                                          getDistanceLabel(
                                                            marina,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            color:
                                                                Colors.white38,
                                                            fontSize: smallSize,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .baseline,
                                                    textBaseline:
                                                        TextBaseline.alphabetic,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Text(
                                                            marina['cheapestPrice'] !=
                                                                    null
                                                                ? ' From ${marina['cheapestPrice']} NOK'
                                                                : 'N/A',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ],
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
                                  );
                                }, childCount: filteredMarinas.length),
                              ),
                            ),

                      SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

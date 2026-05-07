import 'package:flutter/material.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';

class exploreScreen extends StatefulWidget {
  const exploreScreen({super.key});

  @override
  State<exploreScreen> createState() => _exploreScreenState();
}

class _exploreScreenState extends State<exploreScreen> {
  bool loading = false;
  List marinas = [];
  int selectedFilter = 0;
  List<String> filters = ['All', 'Nearby', 'Popular', 'Favorites'];

  @override
  void initState() {
    super.initState();
    loadMarinas();
  }

  Future<void> loadMarinas() async {
    setState(() => loading = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/marinas');
      setState(() => marinas = res.data['marinas']);
    } catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: loading
          ? Center(
              child: CircularProgressIndicator(color: const Color(0xFFC9A84C)),
            )
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        width * 0.05,
                        height * 0.02,
                        width * 0.05,
                        0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Explore marinas',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.07,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: height * 0.004),
                              Text(
                                'Discover premium marinas across Norway',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: width * 0.032,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.all(width * 0.03),
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
                              size: width * 0.055,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        width * 0.05,
                        height * 0.02,
                        width * 0.05,
                        0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.04,
                                vertical: height * 0.015,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A2A3A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.white38,
                                    size: width * 0.05,
                                  ),
                                  SizedBox(width: width * 0.02),
                                  Text(
                                    'Search marina, location or region',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: width * 0.032,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: width * 0.03),
                          Container(
                            padding: EdgeInsets.all(width * 0.035),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2A3A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: width * 0.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        width * 0.05,
                        height * 0.02,
                        width * 0.05,
                        0,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(filters.length, (i) {
                            final selected = selectedFilter == i;
                            return GestureDetector(
                              onTap: () => setState(() => selectedFilter = i),
                              child: Container(
                                margin: EdgeInsets.only(right: width * 0.03),
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.04,
                                  vertical: height * 0.012,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFC9A84C)
                                      : const Color(0xFF1A2A3A),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    if (i == 0)
                                      Icon(
                                        Icons.grid_view_rounded,
                                        color: selected
                                            ? Colors.black
                                            : Colors.white38,
                                        size: width * 0.04,
                                      ),
                                    if (i == 1)
                                      Icon(
                                        Icons.location_on_outlined,
                                        color: selected
                                            ? Colors.black
                                            : Colors.white38,
                                        size: width * 0.04,
                                      ),
                                    if (i == 2)
                                      Icon(
                                        Icons.star_border,
                                        color: selected
                                            ? Colors.black
                                            : Colors.white38,
                                        size: width * 0.04,
                                      ),
                                    if (i == 3)
                                      Icon(
                                        Icons.favorite_border,
                                        color: selected
                                            ? Colors.black
                                            : Colors.white38,
                                        size: width * 0.04,
                                      ),
                                    SizedBox(width: width * 0.015),
                                    Text(
                                      filters[i],
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.black
                                            : Colors.white60,
                                        fontSize: width * 0.033,
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
                      padding: EdgeInsets.fromLTRB(
                        width * 0.05,
                        height * 0.02,
                        width * 0.05,
                        0,
                      ),
                      child: Container(
                        height: height * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/images/portImages/port.jpg',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: EdgeInsets.all(width * 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Summer in Norway',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.055,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: height * 0.006),
                              Text(
                                'Explore breathtaking destinations\nfor your next voyage',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.03,
                                ),
                              ),
                              SizedBox(height: height * 0.012),
                              Row(
                                children: [
                                  Text(
                                    'Explore now',
                                    style: TextStyle(
                                      color: const Color(0xFFC9A84C),
                                      fontSize: width * 0.032,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: width * 0.015),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: const Color(0xFFC9A84C),
                                    size: width * 0.04,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        width * 0.05,
                        height * 0.025,
                        width * 0.05,
                        height * 0.015,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recommended for you',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.045,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'View all',
                            style: TextStyle(
                              color: const Color(0xFFC9A84C),
                              fontSize: width * 0.033,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final marina = marinas[index];
                      final isAvailable = index % 2 == 0;
                      final List<double> ratings = [4.8, 4.7, 4.6, 4.5, 4.9];
                      final List<int> reviews = [126, 89, 72, 54, 143];
                      final rating = ratings[index % ratings.length];
                      final review = reviews[index % reviews.length];

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          width * 0.05,
                          0,
                          width * 0.05,
                          height * 0.015,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2A3A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                    child: Image.asset(
                                      index % 2 == 0
                                          ? 'assets/images/portImages/port.jpg'
                                          : 'assets/images/portImages/port2.png',
                                      width: width * 0.28,
                                      height: width * 0.28,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: GestureDetector(
                                      child: Icon(
                                        Icons.favorite_border,
                                        color: Colors.white,
                                        size: width * 0.05,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: width * 0.03),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: height * 0.015,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              marina['name'],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: width * 0.038,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.02,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isAvailable
                                                  ? const Color(0xFF2D7D4F)
                                                  : const Color(0xFFC4793A),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              isAvailable
                                                  ? 'Available'
                                                  : 'Almost full',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: width * 0.025,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: height * 0.005),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: const Color(0xFFC9A84C),
                                            size: width * 0.035,
                                          ),
                                          SizedBox(width: width * 0.01),
                                          Text(
                                            '$rating ($review)',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: width * 0.03,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: height * 0.005),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            color: Colors.white38,
                                            size: width * 0.033,
                                          ),
                                          SizedBox(width: width * 0.01),
                                          Text(
                                            marina['location'],
                                            style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: width * 0.03,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: height * 0.01),
                                      Row(
                                        children: [
                                          Text(
                                            'From',
                                            style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: width * 0.028,
                                            ),
                                          ),
                                          SizedBox(width: width * 0.015),
                                          Text(
                                            '750 NOK',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: width * 0.038,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: width * 0.03),
                            ],
                          ),
                        ),
                      );
                    }, childCount: marinas.length),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: height * 0.02)),
                ],
              ),
            ),
    );
  }
}

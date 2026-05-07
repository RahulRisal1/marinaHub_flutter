import 'package:flutter/material.dart';
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

  void onSearch() {
    setState(() {
      filteredBookings = bookingsData
          .where(
            (b) =>
                (b['marina_name'] ?? '').toLowerCase().contains(
                  searchController.text.toLowerCase(),
                ) ||
                (b['berth_name'] ?? '').toLowerCase().contains(
                  searchController.text.toLowerCase(),
                ),
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
        bookingsData = res.data['bookings'];
        filteredBookings = bookingsData;
      });
    } catch (e) {
      debugPrint('Bookings error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> cancelBooking(int bookingId) async {
    try {
      final dio = await MyDio().getDio();
      await dio.put('/bookings/$bookingId/cancel');
      await loadMyBookings();
      setState(() => filteredBookings = bookingsData);
    } catch (e) {
      debugPrint('Cancel error: $e');
    }
  }

  Future<void> completeBooking(int bookingId) async {
    try {
      final dio = await MyDio().getDio();
      await dio.put('/bookings/$bookingId/complete');
      await loadMyBookings();
      setState(() => filteredBookings = bookingsData);
    } catch (e) {
      debugPrint('Complete error: $e');
    }
  }

  List<dynamic> get upcomingBookings => filteredBookings.where((b) {
    if (b['status'] != 'confirmed') return false;
    final now = DateTime.now();
    final from = DateTime.parse(b['from_date']).toLocal();
    return now.isBefore(from);
  }).toList();

  List<dynamic> get ongoingBookings => filteredBookings.where((b) {
    if (b['status'] != 'confirmed') return false;
    final now = DateTime.now();
    final from = DateTime.parse(b['from_date']).toLocal();
    final to = DateTime.parse(b['to_date']).toLocal();
    return now.isAfter(from) && now.isBefore(to);
  }).toList();

  List<dynamic> get pastBookings => filteredBookings
      .where((b) => b['status'] == 'cancelled' || b['status'] == 'completed')
      .toList();

  String formatDate(String dateStr) {
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
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int calculateNights(String from, String to) {
    return DateTime.parse(to).difference(DateTime.parse(from)).inDays.abs();
  }

  Color statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF2D7D4F);
      case 'completed':
        return const Color(0xFF1A4A6B);
      default:
        return const Color(0xFF4A4A4A);
    }
  }

  String statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      default:
        return 'Cancelled';
    }
  }

  void showManageDialog(
    BuildContext context,
    dynamic booking,
    double width,
    double height,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Manage booking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageBookingScreen(booking: booking),
                  ),
                );
                if (result == 'refresh') {
                  loadMyBookings();
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: height * 0.015),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFC9A84C).withOpacity(0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Check out',
                    style: TextStyle(
                      color: const Color(0xFFC9A84C),
                      fontWeight: FontWeight.w600,
                      fontSize: width * 0.036,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: height * 0.012),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (ctx2) => AlertDialog(
                    backgroundColor: const Color(0xFF131E2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Cancel booking?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      'Please note that cancelling your booking may result in a cancellation fee. Are you sure you want to cancel?',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: width * 0.034,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2),
                        child: Text(
                          'Back',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx2);
                          cancelBooking(booking['booking_id']);
                        },
                        child: Text(
                          'Yes, cancel',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: height * 0.015),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    'Cancel booking',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: width * 0.036,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                width * 0.05,
                height * 0.02,
                width * 0.05,
                height * 0.02,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF1A2A3A),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'My ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: width * 0.07,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: 'Bookings',
                              style: TextStyle(
                                color: const Color(0xFFC9A84C),
                                fontSize: width * 0.07,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.004),
                      Text(
                        '${bookingsData.length} total reservations',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: width * 0.03,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(width * 0.03),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131E2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF243044),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: width * 0.055,
                        ),
                      ),
                      if (upcomingBookings.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: width * 0.042,
                            height: width * 0.042,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC9A84C),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${upcomingBookings.length}',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: width * 0.022,
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
              padding: EdgeInsets.fromLTRB(
                width * 0.05,
                height * 0.02,
                width * 0.05,
                0,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04,
                  vertical: height * 0.014,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF131E2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF243044),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Colors.white38,
                      size: width * 0.05,
                    ),
                    SizedBox(width: width * 0.02),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.035,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search marina or berth...',
                          hintStyle: TextStyle(
                            color: Colors.white38,
                            fontSize: width * 0.035,
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

            SizedBox(height: height * 0.02),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Container(
                height: height * 0.055,
                decoration: BoxDecoration(
                  color: const Color(0xFF131E2E),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TabBar(
                  controller: tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFFC9A84C),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: TextStyle(
                    fontSize: width * 0.032,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(fontSize: width * 0.032),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Ongoing'),
                    Tab(text: 'Past'),
                  ],
                ),
              ),
            ),

            SizedBox(height: height * 0.02),

            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFFC9A84C),
                      ),
                    )
                  : TabBarView(
                      controller: tabController,
                      children: [
                        buildList(
                          upcomingBookings,
                          true,
                          width,
                          height,
                          emptyText: 'No upcoming bookings',
                          listTitle: 'Upcoming bookings',
                        ),
                        buildList(
                          ongoingBookings,
                          true,
                          width,
                          height,
                          emptyText: 'No ongoing bookings',
                          listTitle: 'Ongoing bookings',
                        ),
                        buildList(
                          pastBookings,
                          false,
                          width,
                          height,
                          emptyText: 'No past bookings',
                          listTitle: 'Past bookings',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildList(
    List<dynamic> bookings,
    bool isUpcoming,
    double width,
    double height, {
    required String emptyText,
    required String listTitle,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.anchor, color: Colors.white12, size: width * 0.15),
            SizedBox(height: height * 0.02),
            Text(
              emptyText,
              style: TextStyle(color: Colors.white38, fontSize: width * 0.038),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              listTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.042,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${bookings.length} bookings',
              style: TextStyle(
                color: const Color(0xFFC9A84C),
                fontSize: width * 0.032,
              ),
            ),
          ],
        ),
        SizedBox(height: height * 0.018),
        ...bookings.map((b) => buildCard(b, isUpcoming, width, height)),
      ],
    );
  }

  Widget buildCard(
    dynamic booking,
    bool isUpcoming,
    double width,
    double height,
  ) {
    final nights = calculateNights(booking['from_date'], booking['to_date']);
    final status = booking['status'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.018),
      decoration: BoxDecoration(
        color: const Color(0xFF131E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/portImages/port.jpg',
                      width: width * 0.3,
                      height: width * 0.38,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.02,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel(status),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.024,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(width * 0.035),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              booking['marina_name'] ?? '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: width * 0.038,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white24,
                            size: width * 0.032,
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.004),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Colors.white38,
                            size: width * 0.03,
                          ),
                          SizedBox(width: 2),
                          Text(
                            booking['berth_name'] ?? '',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: width * 0.028,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.014),
                      Text(
                        'Check-in',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: width * 0.026,
                        ),
                      ),
                      Text(
                        formatDate(booking['from_date']),
                        style: TextStyle(
                          color: const Color(0xFFC9A84C),
                          fontSize: width * 0.029,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: height * 0.008),
                      Text(
                        'Check-out',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: width * 0.026,
                        ),
                      ),
                      Text(
                        formatDate(booking['to_date']),
                        style: TextStyle(
                          color: const Color(0xFFC9A84C),
                          fontSize: width * 0.029,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.04,
              vertical: height * 0.012,
            ),
            child: Row(
              children: [
                buildStat(
                  Icons.anchor,
                  'Berth size',
                  booking['berth_name'] ?? '',
                  width,
                  height,
                ),
                Container(
                  width: 0.5,
                  height: height * 0.04,
                  color: const Color(0xFF243044),
                ),
                buildStat(
                  Icons.nightlight_round,
                  'Nights',
                  '$nights',
                  width,
                  height,
                ),
                Container(
                  width: 0.5,
                  height: height * 0.04,
                  color: const Color(0xFF243044),
                ),
                buildStat(
                  Icons.credit_card_outlined,
                  'Total',
                  '${booking['total_price']} NOK',
                  width,
                  height,
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              width * 0.04,
              0,
              width * 0.04,
              width * 0.04,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: height * 0.014),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFC9A84C),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'View details',
                        style: TextStyle(
                          color: const Color(0xFFC9A84C),
                          fontSize: width * 0.032,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isUpcoming) ...[
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ManageBookingScreen(booking: booking),
                          ),
                        );
                        if (result == 'refresh') {
                          loadMyBookings();
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: height * 0.014),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A84C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Manage booking',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: width * 0.032,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStat(
    IconData icon,
    String label,
    String value,
    double width,
    double height,
  ) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white38, size: width * 0.035),
                SizedBox(width: width * 0.01),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: width * 0.025,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.03,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

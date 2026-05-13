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
  List<dynamic> serviceOrders = [];
  late TabController tabController;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    loadAll();
    searchController.addListener(onSearch);
  }

  @override
  void dispose() {
    tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadAll() async {
    await Future.wait([loadMyBookings(), loadServiceOrders()]);
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
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadServiceOrders() async {
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/service-orders/my');
      setState(() => serviceOrders = res.data['orders'] ?? []);
    } catch (_) {}
  }

  Future<void> cancelServiceOrder(String orderId) async {
    try {
      final dio = await MyDio().getDio();
      await dio.delete('/service-orders/$orderId');
      await loadServiceOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service order cancelled'),
            backgroundColor: Color(0xFF7D2D2D),
          ),
        );
      }
    } catch (e) {
      dioErrorManager(e);
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
        const SnackBar(
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
        const SnackBar(
          content: Text('Checked out! Hope you enjoyed your stay.'),
          backgroundColor: Color(0xFF1A4A6B),
        ),
      );
    } on DioException catch (e) {
      dioErrorManager(e);
    }
  }

  List<dynamic> get upcomingBookings => filteredBookings.where((b) {
    if (b['status'] != 'confirmed') return false;
    final from = DateTime.parse(b['from_date']).toLocal();
    return from.isAfter(DateTime.now());
  }).toList();

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

  List<dynamic> get pastBookings => filteredBookings.where((b) {
    return b['status'] == 'completed' || b['status'] == 'cancelled';
  }).toList();

  // Active service orders (not completed/cancelled)
  List<dynamic> get activeServiceOrders => serviceOrders.where((o) {
    return o['status'] != 'completed' && o['status'] != 'cancelled';
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

  Color statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF2D7D4F);
      case 'checked_in':
        return const Color(0xFF1A6B4A);
      case 'completed':
        return const Color(0xFF1A4A6B);
      case 'cancelled':
        return const Color(0xFF7D2D2D);
      default:
        return const Color(0xFF4A4A4A);
    }
  }

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

  Color serviceStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFF8B6914);
      case 'accepted':
        return const Color(0xFF1A4A6B);
      case 'in_progress':
        return const Color(0xFF1A6B4A);
      case 'completed':
        return const Color(0xFF2D7D4F);
      case 'cancelled':
        return const Color(0xFF7D2D2D);
      default:
        return const Color(0xFF4A4A4A);
    }
  }

  String serviceStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
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
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white38, size: isBig ? 14 : 13),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: isBig ? 12 : 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
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

  // Service orders section shown inside booking card
  Widget buildServiceOrdersSection(bool isBig) {
    if (activeServiceOrders.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(
        isBig ? 18 : 14,
        0,
        isBig ? 18 : 14,
        isBig ? 14 : 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1421),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF243044), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.handyman_outlined, color: Color(0xFFC9A84C), size: 14),
              SizedBox(width: 6),
              Text(
                'Active Service Orders',
                style: TextStyle(
                  color: Color(0xFFC9A84C),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...activeServiceOrders.map(
            (order) => _buildServiceOrderRow(order, isBig),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceOrderRow(dynamic order, bool isBig) {
    final status = order['status'] ?? 'pending';
    final serviceName =
        order['Service']?['name'] ?? order['service']?['name'] ?? 'Service';
    final quantity = order['quantity'] ?? 0;
    final unit = order['unit'] ?? '';
    final total = order['total_price'] ?? 0;
    final currency = order['currency'] ?? 'NOK';
    final orderId = order['id'] as String;
    final canCancel = status == 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: serviceStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$quantity $unit · $total $currency',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: serviceStatusColor(status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: serviceStatusColor(status).withOpacity(0.5),
              ),
            ),
            child: Text(
              serviceStatusLabel(status),
              style: TextStyle(
                color: serviceStatusColor(status),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canCancel) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => cancelServiceOrder(orderId),
              child: const Icon(Icons.close, color: Colors.white38, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildCard(dynamic booking, bool isBig) {
    final status = booking['status'] as String;
    final duration = formatDuration(booking['from_date'], booking['to_date']);
    final imageWidth = isBig ? 200.0 : 120.0;
    final imageHeight = isBig ? 200.0 : 170.0;
    final bookingId = booking['id'] as String;

    final from = DateTime.parse(booking['from_date']).toLocal();
    final now = DateTime.now();
    final diffHours = from.difference(now).inMinutes / 60;
    final canCheckIn =
        status == 'confirmed' &&
        diffHours <= 1 &&
        from.isAfter(now.subtract(const Duration(hours: 24)));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131E2E),
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
                  borderRadius: const BorderRadius.only(
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
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white24,
                              size: 13,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white38,
                              size: 13,
                            ),
                            const SizedBox(width: 3),
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
                            color: const Color(0xFFC9A84C),
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
                            color: const Color(0xFFC9A84C),
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
                Container(
                  width: 0.5,
                  height: 32,
                  color: const Color(0xFF243044),
                ),
                buildStatCell(Icons.access_time, 'Duration', duration, isBig),
                Container(
                  width: 0.5,
                  height: 32,
                  color: const Color(0xFF243044),
                ),
                buildStatCell(
                  Icons.credit_card_outlined,
                  'Total',
                  '${booking['total_price']} NOK',
                  isBig,
                ),
              ],
            ),
          ),

          // Service orders section
          buildServiceOrdersSection(isBig),

          Padding(
            padding: EdgeInsets.fromLTRB(
              isBig ? 18 : 14,
              0,
              isBig ? 18 : 14,
              isBig ? 18 : 14,
            ),
            child: Row(
              children: [
                if (status == 'confirmed' && from.isAfter(now)) ...[
                  const SizedBox(width: 10),
                  buildActionButton(
                    label: 'View Details',
                    color: const Color(0xFFC9A84C),
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
                if (canCheckIn) ...[
                  const SizedBox(width: 10),
                  buildActionButton(
                    label: 'Check In',
                    color: const Color(0xFF2D7D4F),
                    textColor: Colors.white,
                    isBig: isBig,
                    onTap: () => checkIn(bookingId),
                  ),
                ],
                if (status == 'checked_in') ...[
                  const SizedBox(width: 10),
                  buildActionButton(
                    label: 'Check Out',
                    color: const Color(0xFF1A4A6B),
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
            const SizedBox(height: 16),
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
              style: TextStyle(
                color: const Color(0xFFC9A84C),
                fontSize: bodySize,
              ),
            ),
          ],
        ),
        SizedBox(height: isBig ? 16 : 14),
        ...bookings.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
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
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
                  decoration: const BoxDecoration(
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
                                      color: const Color(0xFFC9A84C),
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
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
                      const SizedBox(width: 12),
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC9A84C),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${upcomingBookings.length}',
                                    style: const TextStyle(
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
                      color: const Color(0xFF131E2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF243044),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: Colors.white38,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
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
                const SizedBox(height: 16),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: Container(
                    height: isBig ? 48 : 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131E2E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      controller: tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFFC9A84C),
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
                      tabs: const [
                        Tab(text: 'Upcoming'),
                        Tab(text: 'Ongoing'),
                        Tab(text: 'Past'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: isLoading
                      ? const Center(
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

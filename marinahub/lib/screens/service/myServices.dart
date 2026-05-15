import 'package:flutter/material.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/dio/myDio.dart';

class MyServiceOrdersScreen extends StatefulWidget {
  const MyServiceOrdersScreen({super.key});

  @override
  State<MyServiceOrdersScreen> createState() => _MyServiceOrdersScreenState();
}

class _MyServiceOrdersScreenState extends State<MyServiceOrdersScreen>
    with SingleTickerProviderStateMixin {
  static const Color navy = Color(0xFF0A1628);
  static const Color navyCard = Color(0xFF131E2E);
  static const Color navyCardSoft = Color(0xFF1A2940);
  static const Color gold = Color(0xFFC9A84C);
  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF8B95A8);
  static const Color dividerColor = Color(0xFF243044);

  late TabController tabController;
  bool isLoading = false;
  List<dynamic> allOrders = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    loadOrders();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  List<dynamic> get activeOrders => allOrders
      .where((o) => o['status'] != 'completed' && o['status'] != 'cancelled')
      .toList();

  List<dynamic> get historyOrders => allOrders
      .where((o) => o['status'] == 'completed' || o['status'] == 'cancelled')
      .toList();

  Future<void> loadOrders() async {
    setState(() => isLoading = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/service-orders/my');
      setState(() => allOrders = res.data['orders'] ?? []);
    } catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      final dio = await MyDio().getDio();
      await dio.delete('/service-orders/$orderId');
      await loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Service order cancelled'),
            backgroundColor: const Color(0xFF7D2D2D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      dioErrorManager(e);
    }
  }

  bool isTabletOrUp(double w) => w >= 600;
  double maxContentWidth(double w) {
    if (w >= 1000) return 900;
    if (w >= 600) return 720;
    return w;
  }

  Color statusColor(String status) {
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

  String statusLabel(String status) {
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

  IconData categoryIcon(String? category) {
    switch (category) {
      case 'fuel':
        return Icons.local_gas_station;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'repairs':
        return Icons.build;
      case 'maintenance':
        return Icons.handyman;
      case 'provisioning':
        return Icons.shopping_basket;
      case 'waste_disposal':
        return Icons.delete_outline;
      case 'electricity':
        return Icons.bolt;
      case 'water':
        return Icons.water_drop;
      default:
        return Icons.miscellaneous_services;
    }
  }

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
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]}, $hour:$minute $period';
  }

  Widget buildOrderCard(dynamic order, bool isBig) {
    final status = order['status'] ?? 'pending';
    final service = order['service'] ?? {};
    final serviceName =
        order['Service']?['name'] ?? service['name'] ?? 'Service';
    final category = order['Service']?['category'] ?? service['category'];
    final marinaId = order['marina_id'] ?? '';
    final quantity = order['quantity'] ?? 0;
    final unit = order['unit'] ?? '';
    final totalPrice = order['total_price'] ?? 0;
    final currency = order['currency'] ?? 'NOK';
    final orderNumber = order['order_number'] ?? '';
    final requestedTime = order['requested_time'] ?? 'asap';
    final notes = order['notes'] ?? '';
    final createdAt = order['createdAt'] ?? '';
    final canCancel = status == 'pending';
    final sColor = statusColor(status);

    return Container(
      margin: EdgeInsets.only(bottom: isBig ? 16 : 12),
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: EdgeInsets.fromLTRB(
              isBig ? 18 : 14,
              isBig ? 16 : 14,
              isBig ? 18 : 14,
              0,
            ),
            child: Row(
              children: [
                Container(
                  width: isBig ? 44 : 38,
                  height: isBig ? 44 : 38,
                  decoration: BoxDecoration(
                    color: navyCardSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: dividerColor, width: 0.5),
                  ),
                  child: Icon(
                    categoryIcon(category),
                    color: gold,
                    size: isBig ? 22 : 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: isBig ? 16 : 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        orderNumber,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: isBig ? 12 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusLabel(status),
                    style: TextStyle(
                      color: sColor,
                      fontSize: isBig ? 11.5 : 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isBig ? 18 : 14,
              vertical: isBig ? 14 : 12,
            ),
            child: Container(height: 0.5, color: dividerColor),
          ),

          // Stats row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isBig ? 18 : 14),
            child: Row(
              children: [
                _statCell(
                  Icons.science_outlined,
                  'Quantity',
                  '$quantity $unit'.trim(),
                  isBig,
                ),
                Container(width: 0.5, height: 32, color: dividerColor),
                _statCell(
                  Icons.credit_card_outlined,
                  'Total',
                  '$totalPrice $currency',
                  isBig,
                ),
                Container(width: 0.5, height: 32, color: dividerColor),
                _statCell(
                  Icons.schedule,
                  'Timing',
                  requestedTime == 'asap' ? 'ASAP' : 'Scheduled',
                  isBig,
                ),
              ],
            ),
          ),

          if (notes.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                isBig ? 18 : 14,
                isBig ? 12 : 10,
                isBig ? 18 : 14,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: navyCardSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: dividerColor, width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes, color: textSecondary, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        notes,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: isBig ? 12.5 : 11.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Footer
          Padding(
            padding: EdgeInsets.fromLTRB(
              isBig ? 18 : 14,
              isBig ? 12 : 10,
              isBig ? 18 : 14,
              isBig ? 16 : 14,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  createdAt.isNotEmpty ? formatDate(createdAt) : '',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: isBig ? 11.5 : 10.5,
                  ),
                ),
                if (canCancel)
                  GestureDetector(
                    onTap: () => _confirmCancel(order['id'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7D2D2D).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF7D2D2D).withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: const Color(0xFFE57373),
                          fontSize: isBig ? 12.5 : 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell(IconData icon, String label, String value, bool isBig) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: textSecondary, size: isBig ? 13 : 12),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: isBig ? 11.5 : 10.5,
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
                color: textPrimary,
                fontSize: isBig ? 13 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Order',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to cancel this service order?',
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              cancelOrder(orderId);
            },
            child: const Text(
              'Cancel Order',
              style: TextStyle(
                color: Color(0xFFE57373),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState(String message, bool isBig) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handyman_outlined,
            color: Colors.white12,
            size: isBig ? 72 : 56,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: textSecondary, fontSize: isBig ? 16 : 14),
          ),
        ],
      ),
    );
  }

  Widget buildList(List<dynamic> orders, bool isBig, double hPad) {
    if (orders.isEmpty) {
      return buildEmptyState('No orders found', isBig);
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
      itemCount: orders.length,
      itemBuilder: (_, i) => buildOrderCard(orders[i], isBig),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isBig = isTabletOrUp(width);
    final hPad = isBig ? 28.0 : 20.0;
    final titleSize = isBig ? 32.0 : 26.0;
    final tabFontSize = isBig ? 14.0 : 12.5;

    return Scaffold(
      backgroundColor: navy,

      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 56,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: textPrimary,
          style: IconButton.styleFrom(backgroundColor: navyCard),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Services',
              style: TextStyle(
                color: textPrimary,
                fontSize: isBig ? 20 : 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${allOrders.length} total orders',
              style: TextStyle(
                color: textSecondary,
                fontSize: isBig ? 12 : 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: loadOrders,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: textPrimary,
              style: IconButton.styleFrom(
                backgroundColor: navyCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: dividerColor, width: 0.5),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: const Color(0xFF1A2A3A), height: 0.5),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tab bar
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                  child: Container(
                    height: isBig ? 48 : 42,
                    decoration: BoxDecoration(
                      color: navyCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      controller: tabController,
                      indicator: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.black,
                      unselectedLabelColor: textSecondary,
                      labelStyle: TextStyle(
                        fontSize: tabFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(fontSize: tabFontSize),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Active'),
                              if (activeOrders.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${activeOrders.length}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Tab(text: 'History'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Body
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: gold),
                        )
                      : TabBarView(
                          controller: tabController,
                          children: [
                            buildList(activeOrders, isBig, hPad),
                            buildList(historyOrders, isBig, hPad),
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

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/utils/colors.dart';

class AdminOrdersPage extends StatefulWidget {
  AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List orders = [];
  List filtered = [];
  bool loading = true;
  String activeFilter = 'all';

  List<String> filters = [
    'all',
    'pending',
    'accepted',
    'in_progress',
    'completed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() => loading = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/service-orders/all');
      List all = res.data['orders'] ?? [];
      setState(() {
        orders = all;
        applyFilter();
      });
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loading = false);
    }
  }

  void applyFilter() {
    if (activeFilter == 'all') {
      filtered = List.from(orders);
    } else {
      filtered = orders.where((o) => o['status'] == activeFilter).toList();
    }
  }

  Future<void> updateStatus(String orderId, String status) async {
    try {
      final dio = await MyDio().getDio();
      await dio.patch(
        '/service-orders/$orderId/status',
        data: {'status': status},
      );
      loadOrders();
      showSnack('Order marked as $status');
    } on DioException catch (e) {
      dioErrorManager(e);
    }
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: textPrimary)),
        backgroundColor: navyCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void showStatusPicker(Map order) {
    List<String> allowed = [
      'accepted',
      'in_progress',
      'completed',
      'cancelled',
    ];
    String current = order['status'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: navyCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: divider, width: 0.8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Update Order Status',
              style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              order['order_number'] ?? '',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            SizedBox(height: 16),
            ...allowed.map((s) {
              bool isCurrent = s == current;
              Color sc = s == 'completed'
                  ? accentGreen
                  : s == 'in_progress'
                  ? accentBlue
                  : s == 'accepted'
                  ? gold
                  : danger;
              return GestureDetector(
                onTap: isCurrent
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        updateStatus(order['id'], s);
                      },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: isCurrent ? sc.withOpacity(0.15) : fieldColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent ? sc.withOpacity(0.4) : divider,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sc,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        s.replaceAll('_', ' '),
                        style: TextStyle(
                          color: isCurrent ? sc : textPrimary,
                          fontSize: 14,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      if (isCurrent) ...[
                        Spacer(),
                        Text(
                          'current',
                          style: TextStyle(color: sc, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case 'completed':
        return accentGreen;
      case 'in_progress':
        return accentBlue;
      case 'accepted':
        return gold;
      case 'cancelled':
        return danger;
      default:
        return textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Orders',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
                itemBuilder: (context, i) {
                  String f = filters[i];
                  bool isActive = activeFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() {
                      activeFilter = f;
                      applyFilter();
                    }),
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? gold : navyCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? gold : divider,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        f == 'all' ? 'All' : f.replaceAll('_', ' '),
                        style: TextStyle(
                          color: isActive ? navy : textSecondary,
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                color: gold,
                backgroundColor: navyCard,
                onRefresh: loadOrders,
                child: loading
                    ? Center(child: CircularProgressIndicator(color: gold))
                    : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No orders found',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          Map o = filtered[i];
                          String status = o['status'] ?? '';
                          Color sc = statusColor(status);
                          return GestureDetector(
                            onTap: () => showStatusPicker(o),
                            child: Container(
                              margin: EdgeInsets.only(bottom: 10),
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: navyCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: divider, width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: sc.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long,
                                      color: sc,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          o['order_number'] ?? '',
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          o['service']?['name'] ?? 'Service',
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          '${o['total_price'] ?? 0} NOK · qty ${o['quantity'] ?? 1}',
                                          style: TextStyle(
                                            color: gold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: sc.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          status.replaceAll('_', ' '),
                                          style: TextStyle(
                                            color: sc,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Icon(
                                        Icons.chevron_right,
                                        color: textSecondary,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

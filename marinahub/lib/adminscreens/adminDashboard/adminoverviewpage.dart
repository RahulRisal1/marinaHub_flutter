import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/utils/colors.dart';

class AdminOverviewPage extends StatefulWidget {
  AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  List marinas = [];
  List berths = [];
  List bookings = [];
  List users = [];
  List orders = [];

  bool loadingMarinas = true;
  bool loadingBerths = true;
  bool loadingBookings = true;
  bool loadingUsers = true;
  bool loadingOrders = true;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadMarinas(),
      loadBerths(),
      loadBookings(),
      loadUsers(),
      loadOrders(),
    ]);
  }

  Future<void> loadMarinas() async {
    setState(() => loadingMarinas = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/marinas');
      setState(() => marinas = res.data['marinas'] ?? []);
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loadingMarinas = false);
    }
  }

  Future<void> loadBerths() async {
    setState(() => loadingBerths = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/berths');
      setState(() => berths = res.data['berths'] ?? []);
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loadingBerths = false);
    }
  }

  Future<void> loadBookings() async {
    setState(() => loadingBookings = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/bookings/all');
      setState(() => bookings = res.data['bookings'] ?? []);
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loadingBookings = false);
    }
  }

  Future<void> loadUsers() async {
    setState(() => loadingUsers = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/users/all');
      setState(() => users = res.data['users'] ?? []);
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loadingUsers = false);
    }
  }

  Future<void> loadOrders() async {
    setState(() => loadingOrders = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/service-orders/all');
      setState(() => orders = res.data['orders'] ?? []);
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loadingOrders = false);
    }
  }

  int get activeBookings => bookings
      .where((b) => b['status'] == 'confirmed' || b['status'] == 'checked_in')
      .length;
  int get pendingOrders => orders.where((o) => o['status'] == 'pending').length;
  double get totalRevenue => bookings.fold(
    0.0,
    (sum, b) => sum + ((b['total_price'] ?? 0) as num).toDouble(),
  );

  String formatRevenue(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.toStringAsFixed(0);
  }

  Widget buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool loading,
  ) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Spacer(),
              Icon(Icons.trending_up, color: color.withOpacity(0.4), size: 13),
            ],
          ),
          SizedBox(height: 10),
          loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: textSecondary, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    int crossCount = width > 600 ? 3 : 2;

    List<Map<String, dynamic>> stats = [
      {
        'label': 'Total Marinas',
        'value': '${marinas.length}',
        'icon': Icons.location_on_outlined,
        'color': accentBlue,
        'loading': loadingMarinas,
      },
      {
        'label': 'Total Berths',
        'value': '${berths.length}',
        'icon': Icons.directions_boat_outlined,
        'color': accentGreen,
        'loading': loadingBerths,
      },
      {
        'label': 'Active Bookings',
        'value': '$activeBookings',
        'icon': Icons.calendar_today_outlined,
        'color': gold,
        'loading': loadingBookings,
      },
      {
        'label': 'Pending Orders',
        'value': '$pendingOrders',
        'icon': Icons.receipt_long_outlined,
        'color': Color(0xFF9B59B6),
        'loading': loadingOrders,
      },
      {
        'label': 'Total Users',
        'value': '${users.length}',
        'icon': Icons.people_outline,
        'color': danger,
        'loading': loadingUsers,
      },
      {
        'label': 'Revenue',
        'value': '${formatRevenue(totalRevenue)} NOK',
        'icon': Icons.bar_chart_outlined,
        'color': accentGreen,
        'loading': loadingBookings,
      },
    ];

    return Scaffold(
      backgroundColor: navy,
      body: RefreshIndicator(
        color: gold,
        backgroundColor: navyCard,
        onRefresh: loadAll,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 16,
            16,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Portal',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                        SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                            children: [
                              TextSpan(text: 'Marina'),
                              TextSpan(
                                text: 'Hub',
                                style: TextStyle(color: gold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentGreen,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Live',
                          style: TextStyle(
                            color: accentGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),
              Text(
                'AT A GLANCE',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.45,
                ),
                itemCount: stats.length,
                itemBuilder: (context, i) {
                  Map<String, dynamic> s = stats[i];
                  return buildStatCard(
                    s['label'],
                    s['value'],
                    s['icon'],
                    s['color'],
                    s['loading'],
                  );
                },
              ),

              SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'RECENT BOOKINGS',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                ],
              ),
              SizedBox(height: 10),
              loadingBookings
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: gold),
                      ),
                    )
                  : bookings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No bookings yet',
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: navyCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: divider, width: 0.8),
                      ),
                      child: Column(
                        children: bookings.take(5).toList().asMap().entries.map(
                          (entry) {
                            int i = entry.key;
                            Map b = entry.value;
                            String status = b['status'] ?? '';
                            Color statusColor = status == 'confirmed'
                                ? accentGreen
                                : status == 'checked_in'
                                ? accentBlue
                                : status == 'cancelled'
                                ? danger
                                : gold;
                            return Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 11,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.anchor,
                                          color: statusColor,
                                          size: 15,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              b['marina']?['name'] ?? 'Marina',
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              b['user']?['name'] ??
                                                  b['user']?['email'] ??
                                                  'User',
                                              style: TextStyle(
                                                color: textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            '${b['total_price'] ?? 0} NOK',
                                            style: TextStyle(
                                              color: gold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (i < 4)
                                  Divider(
                                    height: 0,
                                    thickness: 0.5,
                                    color: divider,
                                  ),
                              ],
                            );
                          },
                        ).toList(),
                      ),
                    ),

              SizedBox(height: 20),
              Text(
                'RECENT USERS',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10),
              loadingUsers
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: gold),
                      ),
                    )
                  : users.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No users yet',
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: navyCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: divider, width: 0.8),
                      ),
                      child: Column(
                        children: users.take(4).toList().asMap().entries.map((
                          entry,
                        ) {
                          int i = entry.key;
                          Map u = entry.value;
                          return Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: gold.withOpacity(0.15),
                                      child: Text(
                                        (u['name'] ?? 'U')
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: gold,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            u['name'] ?? 'Unknown',
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            u['email'] ?? '',
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (u['role'] == 'admin'
                                                    ? gold
                                                    : accentBlue)
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        u['role'] ?? 'boater',
                                        style: TextStyle(
                                          color: u['role'] == 'admin'
                                              ? gold
                                              : accentBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < 3)
                                Divider(
                                  height: 0,
                                  thickness: 0.5,
                                  color: divider,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

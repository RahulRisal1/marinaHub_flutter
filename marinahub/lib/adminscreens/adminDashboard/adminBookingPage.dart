import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/utils/colors.dart';

class AdminBookingsPage extends StatefulWidget {
  AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> {
  List bookings = [];
  List filtered = [];
  bool loading = true;

  String statusFilter = 'all';
  String sortBy = 'newest';
  TextEditingController searchCtrl = TextEditingController();

  List<String> statusFilters = [
    'all',
    'confirmed',
    'checked_in',
    'completed',
    'cancelled',
  ];

  List<Map<String, String>> sortOptions = [
    {'key': 'newest', 'label': 'Newest first'},
    {'key': 'oldest', 'label': 'Oldest first'},
    {'key': 'price_high', 'label': 'Price: high → low'},
    {'key': 'price_low', 'label': 'Price: low → high'},
  ];

  @override
  void initState() {
    super.initState();
    loadBookings();
    searchCtrl.addListener(applyFilters);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadBookings() async {
    setState(() => loading = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/bookings/all');
      setState(() {
        bookings = res.data['bookings'] ?? [];
        applyFilters();
      });
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loading = false);
    }
  }

  void applyFilters() {
    List result = List.from(bookings);

    // Status filter
    if (statusFilter != 'all') {
      result = result.where((b) => b['status'] == statusFilter).toList();
    }

    // Search — marina name, berth name, user name/email
    String q = searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((b) {
        String marina = (b['marina']?['name'] ?? '').toString().toLowerCase();
        String berth = (b['berth']?['name'] ?? '').toString().toLowerCase();
        String user = (b['user']?['name'] ?? b['user']?['email'] ?? '')
            .toString()
            .toLowerCase();
        return marina.contains(q) || berth.contains(q) || user.contains(q);
      }).toList();
    }

    // Sort
    result.sort((a, b) {
      switch (sortBy) {
        case 'oldest':
          return (a['createdAt'] ?? '').compareTo(b['createdAt'] ?? '');
        case 'price_high':
          return ((b['total_price'] ?? 0) as num).compareTo(
            (a['total_price'] ?? 0) as num,
          );
        case 'price_low':
          return ((a['total_price'] ?? 0) as num).compareTo(
            (b['total_price'] ?? 0) as num,
          );
        default: // newest
          return (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? '');
      }
    });

    setState(() => filtered = result);
  }

  Color statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return accentGreen;
      case 'checked_in':
        return accentBlue;
      case 'completed':
        return gold;
      case 'cancelled':
        return danger;
      default:
        return textSecondary;
    }
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'checked_in':
        return Icons.login;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  String formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      DateTime dt = DateTime.parse(raw).toLocal();
      return '${dt.day} ${_month(dt.month)} ${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  String _month(int m) {
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
    return months[m - 1];
  }

  // Summary counts
  int get totalCount => bookings.length;
  int get confirmedCount =>
      bookings.where((b) => b['status'] == 'confirmed').length;
  int get checkedInCount =>
      bookings.where((b) => b['status'] == 'checked_in').length;
  int get completedCount =>
      bookings.where((b) => b['status'] == 'completed').length;
  int get cancelledCount =>
      bookings.where((b) => b['status'] == 'cancelled').length;
  double get totalRevenue => bookings
      .where((b) => b['status'] != 'cancelled')
      .fold(0.0, (sum, b) => sum + ((b['total_price'] ?? 0) as num).toDouble());

  void showSortSheet() {
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
              'Sort by',
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            ...sortOptions.map((opt) {
              bool isActive = sortBy == opt['key'];
              return GestureDetector(
                onTap: () {
                  setState(() => sortBy = opt['key']!);
                  applyFilters();
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: isActive ? gold.withOpacity(0.1) : fieldColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? gold.withOpacity(0.4) : divider,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt['label']!,
                          style: TextStyle(
                            color: isActive ? gold : textPrimary,
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isActive) Icon(Icons.check, color: gold, size: 16),
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

  Widget buildSummaryRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          buildSummaryChip('Total', '$totalCount', textSecondary),
          SizedBox(width: 8),
          buildSummaryChip('Confirmed', '$confirmedCount', accentGreen),
          SizedBox(width: 8),
          buildSummaryChip('Checked in', '$checkedInCount', accentBlue),
          SizedBox(width: 8),
          buildSummaryChip('Completed', '$completedCount', gold),
          SizedBox(width: 8),
          buildSummaryChip('Cancelled', '$cancelledCount', danger),
          SizedBox(width: 8),
          buildSummaryChip(
            'Revenue',
            '${totalRevenue.toStringAsFixed(0)} NOK',
            accentGreen,
          ),
        ],
      ),
    );
  }

  Widget buildSummaryChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget buildBookingCard(Map b, double width) {
    String status = b['status'] ?? '';
    Color sc = statusColor(status);
    bool isNarrow = width < 360;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: marina + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon(status), color: sc, size: 18),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['marina']?['name'] ?? 'Marina',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      b['user']?['name'] ?? b['user']?['email'] ?? 'User',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    color: sc,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10),
          Divider(height: 0, thickness: 0.5, color: divider),
          SizedBox(height: 10),

          // Details row
          isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildDetailItem(
                      Icons.anchor,
                      b['berth']?['name'] ?? 'Berth',
                    ),
                    SizedBox(height: 6),
                    buildDetailItem(
                      Icons.calendar_today_outlined,
                      formatDate(b['from_date']),
                    ),
                    SizedBox(height: 6),
                    buildDetailItem(Icons.logout, formatDate(b['to_date'])),
                    SizedBox(height: 6),
                    buildDetailItem(
                      Icons.payments_outlined,
                      '${b['total_price'] ?? 0} NOK',
                      color: gold,
                    ),
                  ],
                )
              : Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    buildDetailItem(
                      Icons.anchor,
                      b['berth']?['name'] ?? 'Berth',
                    ),
                    buildDetailItem(
                      Icons.login,
                      'In: ${formatDate(b['from_date'])}',
                    ),
                    buildDetailItem(
                      Icons.logout,
                      'Out: ${formatDate(b['to_date'])}',
                    ),
                    buildDetailItem(
                      Icons.payments_outlined,
                      '${b['total_price'] ?? 0} NOK',
                      color: gold,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget buildDetailItem(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color ?? textSecondary, size: 12),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(color: color ?? textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Bookings',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: showSortSheet,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: sortBy != 'newest'
                            ? gold.withOpacity(0.1)
                            : navyCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sortBy != 'newest'
                              ? gold.withOpacity(0.4)
                              : divider,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sort,
                            color: sortBy != 'newest' ? gold : textSecondary,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Sort',
                            style: TextStyle(
                              color: sortBy != 'newest' ? gold : textSecondary,
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

            // Search bar
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: navyCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: divider, width: 0.8),
                ),
                child: TextField(
                  controller: searchCtrl,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search marina, berth, user...',
                    hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search,
                      color: textSecondary,
                      size: 18,
                    ),
                    suffixIcon: searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              searchCtrl.clear();
                              applyFilters();
                            },
                            child: Icon(
                              Icons.close,
                              color: textSecondary,
                              size: 16,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                    isDense: true,
                  ),
                ),
              ),
            ),

            // Status filter chips
            SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: statusFilters.length,
                itemBuilder: (context, i) {
                  String f = statusFilters[i];
                  bool isActive = statusFilter == f;
                  Color fc = f == 'all' ? gold : statusColor(f);
                  return GestureDetector(
                    onTap: () {
                      setState(() => statusFilter = f);
                      applyFilters();
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? fc : navyCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? fc : divider,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        f == 'all' ? 'All' : f.replaceAll('_', ' '),
                        style: TextStyle(
                          color: isActive
                              ? (f == 'all' ? navy : Colors.white)
                              : textSecondary,
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

            SizedBox(height: 10),

            // Summary stats row
            if (!loading && bookings.isNotEmpty) ...[
              buildSummaryRow(),
              SizedBox(height: 10),
            ],

            // Results count
            if (!loading)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '${filtered.length} booking${filtered.length == 1 ? '' : 's'}${searchCtrl.text.isNotEmpty || statusFilter != 'all' ? ' found' : ''}',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ),

            // List
            Expanded(
              child: RefreshIndicator(
                color: gold,
                backgroundColor: navyCard,
                onRefresh: loadBookings,
                child: loading
                    ? Center(child: CircularProgressIndicator(color: gold))
                    : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              color: textSecondary,
                              size: 40,
                            ),
                            SizedBox(height: 12),
                            Text(
                              bookings.isEmpty
                                  ? 'No bookings yet'
                                  : 'No results found',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            if (searchCtrl.text.isNotEmpty ||
                                statusFilter != 'all') ...[
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  searchCtrl.clear();
                                  setState(() => statusFilter = 'all');
                                  applyFilters();
                                },
                                child: Text(
                                  'Clear filters',
                                  style: TextStyle(color: gold, fontSize: 13),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) =>
                            buildBookingCard(filtered[i], width),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/screens/bookings/manageBookingScren.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ── Info banner dismiss (hidden for 24 h via SharedPrefs) ───────────────
  bool _showInfoBanner = false;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    loadAll();
    searchController.addListener(onSearch);
    _loadBannerVisibility();
  }

  @override
  void dispose() {
    tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ── Banner: show unless dismissed in last 24 h ───────────────────────────
  Future<void> _loadBannerVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedAt = prefs.getInt('bookings_banner_dismissed_at') ?? 0;
    final hoursSince = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(dismissedAt))
        .inHours;
    // Show banner if never dismissed or dismissed more than 24 h ago
    if (mounted)
      setState(() => _showInfoBanner = dismissedAt == 0 || hoursSince >= 24);
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'bookings_banner_dismissed_at',
      DateTime.now().millisecondsSinceEpoch,
    );
    if (mounted) setState(() => _showInfoBanner = false);
  }

  String _formatResetTime(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  // ── Data loading ──────────────────────────────────────────────────────────
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

  // ── Check-in / Check-out with early-access guard ──────────────────────────
  Future<void> handleCheckIn(String bookingId, DateTime from) async {
    final now = DateTime.now();
    final minutesUntilFrom = from.difference(now).inMinutes;

    // Too early — more than 5 minutes before check-in time
    if (from.isAfter(now) && minutesUntilFrom > 5) {
      final h = minutesUntilFrom ~/ 60;
      final m = minutesUntilFrom % 60;
      final timeStr = h > 0 ? '${h}h ${m}min' : '${m} min';
      _showEarlyCheckInDialog(from, timeStr);
      return;
    }

    // Past check-out time
    final toDateStr =
        bookingsData.firstWhere(
              (b) => b['id'] == bookingId,
              orElse: () => {'to_date': from.toIso8601String()},
            )['to_date']
            as String;
    final to = DateTime.parse(toDateStr).toLocal();
    if (now.isAfter(to)) {
      _showDialog(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFF7D2D2D),
        title: 'Check-in Window Closed',
        message:
            'Your booking ended on ${formatDateTime(toDateStr)}. You can no longer check in. Please contact the marina for assistance.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFC9A84C))),
          ),
        ],
      );
      return;
    }

    // Within valid window — ask confirmation
    final marina = marinaName(
      bookingsData.firstWhere((b) => b['id'] == bookingId, orElse: () => {}),
    );
    final confirmed = await _showConfirmDialog(
      title: 'Confirm Check-In',
      message: 'You are about to check in at $marina. Are you sure?',
      confirmLabel: 'Check In',
      confirmColor: const Color(0xFF2D7D4F),
    );
    if (confirmed == true) await _doCheckIn(bookingId);
  }

  Future<void> handleCheckOut(String bookingId) async {
    final confirmed = await _showConfirmDialog(
      title: 'Confirm Check-Out',
      message:
          'Are you sure you want to check out? We hope you enjoyed your stay!',
      confirmLabel: 'Check Out',
      confirmColor: const Color(0xFF1A4A6B),
    );
    if (confirmed == true) await _doCheckOut(bookingId);
  }

  Future<void> _doCheckIn(String bookingId) async {
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

  Future<void> _doCheckOut(String bookingId) async {
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

  void _showEarlyCheckInDialog(DateTime from, String timeLeft) {
    final months = [
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
    final h = from.hour == 0
        ? 12
        : (from.hour > 12 ? from.hour - 12 : from.hour);
    final m = from.minute.toString().padLeft(2, '0');
    final p = from.hour >= 12 ? 'PM' : 'AM';
    final dateLabel = '${from.day} ${months[from.month - 1]} at $h:$m $p';

    _showDialog(
      icon: Icons.schedule_rounded,
      iconColor: const Color(0xFFC9A84C),
      title: 'Too Early to Check In',
      message:
          'Check-in opens 5 minutes before your booking starts.\n\n'
          'Your check-in time is $dateLabel.\n'
          'Please come back in $timeLeft.',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Got it',
            style: TextStyle(color: Color(0xFFC9A84C)),
          ),
        ),
      ],
    );
  }

  void _showDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required List<Widget> actions,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF131E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(icon, color: iconColor, size: 40),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white60, height: 1.5),
        ),
        actions: actions,
      ),
    );
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF131E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white60, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: confirmColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking category getters ──────────────────────────────────────────────
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

  List<dynamic> get activeServiceOrders => serviceOrders.where((o) {
    return o['status'] != 'completed' && o['status'] != 'cancelled';
  }).toList();

  // ── Formatting helpers ────────────────────────────────────────────────────
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

  // ── Reusable sub-widgets ──────────────────────────────────────────────────
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
    IconData? icon,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textColor, size: isBig ? 16 : 14),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: isBig ? 14 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Info banner shown at top of page ──────────────────────────────────────
  Widget _buildInfoBanner(bool isBig) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isBig ? 18 : 14,
        vertical: isBig ? 14 : 12,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF112236)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3048), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with X dismiss button
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFC9A84C),
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'About My Bookings',
                  style: TextStyle(
                    color: const Color(0xFFC9A84C),
                    fontSize: isBig ? 13.5 : 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _dismissBanner,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white38,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(
            Icons.anchor_rounded,
            'Manage all your marina berth bookings in one place.',
            isBig,
          ),
          _infoRow(
            Icons.login_rounded,
            'Check-in opens 5 minutes before your booking start time.',
            isBig,
          ),
          _infoRow(
            Icons.logout_rounded,
            'Check-out is available any time once you are checked in.',
            isBig,
          ),
          _infoRow(
            Icons.handyman_outlined,
            'Active service orders for each booking are shown on the card.',
            isBig,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(height: 0.5, color: const Color(0xFF1E3048)),
          ),
          Row(
            children: [
              const Icon(
                Icons.refresh_rounded,
                color: Colors.white24,
                size: 13,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'This notice resets every 24 hours. Tap × to hide it for today.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isBig) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white38, size: isBig ? 13 : 12),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white54,
                fontSize: isBig ? 12 : 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Service orders section ────────────────────────────────────────────────
  Widget buildServiceOrdersSection(dynamic booking, bool isBig) {
    final bookingId = booking['id'] as String;
    final orders = activeServiceOrders
        .where((o) => o['booking_id'] == bookingId)
        .toList();
    if (orders.isEmpty) return const SizedBox.shrink();

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
          ...orders.map((order) => _buildServiceOrderRow(order, isBig)),
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

  // ── Check-in status chip (informative, always visible) ────────────────────
  Widget _buildCheckInStatusChip(
    String status,
    DateTime from,
    DateTime to,
    bool isBig,
  ) {
    final now = DateTime.now();
    final minutesUntil = from.difference(now).inMinutes;
    final isCheckedIn = status == 'checked_in';
    final isCompleted = status == 'completed' || status == 'cancelled';
    final withinWindow = minutesUntil <= 5 && !now.isAfter(to);

    Color chipColor;
    IconData chipIcon;
    String chipText;

    if (isCheckedIn) {
      chipColor = const Color(0xFF1A6B4A);
      chipIcon = Icons.check_circle_outline_rounded;
      chipText = 'Currently checked in';
    } else if (isCompleted) {
      chipColor = const Color(0xFF243044);
      chipIcon = Icons.history_rounded;
      chipText = status == 'completed' ? 'Stay completed' : 'Cancelled';
    } else if (withinWindow) {
      chipColor = const Color(0xFF2D7D4F);
      chipIcon = Icons.login_rounded;
      chipText = 'Ready to check in';
    } else if (from.isAfter(now)) {
      final minsLeft = minutesUntil;
      final display = minsLeft > 60
          ? '~${(minsLeft / 60).ceil()}h'
          : '~${minsLeft}min';
      chipColor = const Color(0xFF1E3048);
      chipIcon = Icons.schedule_rounded;
      chipText = 'Check-in in $display';
    } else {
      chipColor = const Color(0xFF1E3048);
      chipIcon = Icons.info_outline_rounded;
      chipText = 'Check-in window active';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.5), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipIcon,
            color: chipColor == const Color(0xFF243044)
                ? Colors.white38
                : const Color(0xFFC9A84C),
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: TextStyle(
              color: chipColor == const Color(0xFF243044)
                  ? Colors.white38
                  : Colors.white70,
              fontSize: isBig ? 11 : 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Booking card ──────────────────────────────────────────────────────────
  Widget buildCard(dynamic booking, bool isBig) {
    final status = booking['status'] as String;
    final duration = formatDuration(booking['from_date'], booking['to_date']);
    final imageWidth = isBig ? 200.0 : 120.0;
    final imageHeight = isBig ? 200.0 : 170.0;
    final bookingId = booking['id'] as String;

    final from = DateTime.parse(booking['from_date']).toLocal();
    final to = DateTime.parse(booking['to_date']).toLocal();
    final now = DateTime.now();
    final minutesUntilFrom = from.difference(now).inMinutes;

    // within 5-minute window and booking not yet expired
    final canCheckIn =
        status == 'confirmed' && minutesUntilFrom <= 5 && !now.isAfter(to);

    // Whole-card taps navigate to detail
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageBookingScreen(booking: booking),
          ),
        );
        if (result == 'refresh') loadMyBookings();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A2A3A), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top image + info row ────────────────────────────────────
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
                          const SizedBox(height: 8),
                          // Always-visible check-in status chip
                          _buildCheckInStatusChip(status, from, to, isBig),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Stats row ───────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isBig ? 18 : 14,
                vertical: isBig ? 14 : 12,
              ),
              child: Row(
                children: [
                  buildStatCell(
                    Icons.anchor,
                    'Berth',
                    berthName(booking),
                    isBig,
                  ),
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

            // ── Service orders ───────────────────────────────────────────
            buildServiceOrdersSection(booking, isBig),

            // ── Action buttons — ALWAYS visible ─────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                isBig ? 18 : 14,
                0,
                isBig ? 18 : 14,
                isBig ? 18 : 14,
              ),
              child: Row(
                children: [
                  // Details button — always shown
                  buildActionButton(
                    label: 'Details',
                    color: Colors.transparent,
                    textColor: const Color(0xFFC9A84C),
                    outlined: true,
                    isBig: isBig,
                    icon: Icons.info_outline_rounded,
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

                  const SizedBox(width: 10),

                  // Check In button — shown for all confirmed (active or early)
                  if (status == 'confirmed') ...[
                    buildActionButton(
                      label: 'Check In',
                      color: canCheckIn
                          ? const Color(0xFF2D7D4F)
                          : const Color(0xFF1E2E3A),
                      textColor: canCheckIn ? Colors.white : Colors.white38,
                      isBig: isBig,
                      icon: Icons.login_rounded,
                      onTap: () => handleCheckIn(bookingId, from),
                    ),
                  ],

                  // Check Out button — shown when checked in
                  if (status == 'checked_in') ...[
                    buildActionButton(
                      label: 'Check Out',
                      color: const Color(0xFF1A4A6B),
                      textColor: Colors.white,
                      isBig: isBig,
                      icon: Icons.logout_rounded,
                      onTap: () => handleCheckOut(bookingId),
                    ),
                  ],

                  // Completed/Cancelled — no check-in/out, just details
                  if (status == 'completed' || status == 'cancelled') ...[
                    buildActionButton(
                      label: status == 'completed'
                          ? 'View Receipt'
                          : 'View Details',
                      color: const Color(0xFF1A4A6B),
                      textColor: Colors.white,
                      isBig: isBig,
                      icon: status == 'completed'
                          ? Icons.receipt_long_rounded
                          : Icons.info_outline_rounded,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
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
              '${bookings.length} booking${bookings.length == 1 ? '' : 's'}',
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

  // ── Build ─────────────────────────────────────────────────────────────────
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
                // ── STICKY HEADER ─────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF0A1628)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page title + subtitle
                      Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Bookings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track, check in and manage all your marina stays',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: subtitleSize,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── INFO BANNER ───────────────────────────────────
                      if (_showInfoBanner) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          child: _buildInfoBanner(isBig),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── SEARCH BAR ────────────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isBig ? 14 : 13,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1C2E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF243044),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: Color(0xFFC9A84C),
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
                                      color: Colors.white24,
                                      fontSize: bodySize,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              if (searchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () => searchController.clear(),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white38,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── TAB BAR ───────────────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Container(
                          height: isBig ? 48 : 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1C2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF243044),
                              width: 0.5,
                            ),
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
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle: TextStyle(
                              fontSize: tabFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                            dividerColor: Colors.transparent,
                            tabs: [
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Upcoming'),
                                    if (upcomingBookings.isNotEmpty) ...[
                                      const SizedBox(width: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${upcomingBookings.length}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Ongoing'),
                                    if (ongoingBookings.isNotEmpty) ...[
                                      const SizedBox(width: 5),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${ongoingBookings.length}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Tab(text: 'Past'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Container(height: 0.5, color: const Color(0xFF1A2A3A)),
                    ],
                  ),
                ),

                // ── CONTENT ───────────────────────────────────────────────
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

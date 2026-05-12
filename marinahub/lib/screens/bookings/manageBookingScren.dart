import 'package:flutter/material.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';

class ManageBookingScreen extends StatefulWidget {
  final dynamic booking;
  const ManageBookingScreen({super.key, required this.booking});

  @override
  State<ManageBookingScreen> createState() => _ManageBookingScreenState();
}

class _ManageBookingScreenState extends State<ManageBookingScreen> {
  bool actionLoading = false;
  late dynamic booking;

  @override
  void initState() {
    super.initState();
    booking = widget.booking;
  }

  String get marinaName => booking['marina']?['name'] ?? '';
  String get berthName => booking['berth']?['name'] ?? '';
  String get bookingId => booking['id'] ?? '';
  String get status => booking['status'] ?? 'confirmed';

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
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}, $hour:$minute $period';
  }

  String formatDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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

  void showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> checkIn() async {
    final from = DateTime.parse(booking['from_date']).toLocal();
    final to = DateTime.parse(booking['to_date']).toLocal();
    final now = DateTime.now();

    if (now.isAfter(to)) {
      showConfirmDialog(
        'Check-in expired',
        'Your booking ended on ${formatDateTime(booking['to_date'])}. You can no longer check in.',
        'Got it',
        Colors.red,
        () {},
      );
      return;
    }

    final minutesBefore = from.difference(now).inMinutes;
    if (minutesBefore > 5) {
      showConfirmDialog(
        'Too early to check in',
        'You can only check in 5 minutes before your booking starts. Your check-in time is ${formatDateTime(booking['from_date'])}.',
        'Got it',
        Color(0xFFC9A84C),
        () {},
      );
      return;
    }

    setState(() => actionLoading = true);
    try {
      final dio = await MyDio().getDio();
      await dio.patch('/bookings/$bookingId/checkin');
      if (!mounted) return;
      showSnack('Checked in successfully!', Color(0xFF2D7D4F));
      Navigator.pop(context, 'refresh');
    } catch (e) {
      dioErrorManager(e);
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> checkOut() async {
    setState(() => actionLoading = true);
    try {
      final dio = await MyDio().getDio();
      await dio.patch('/bookings/$bookingId/checkout');
      if (!mounted) return;
      showSnack('Checked out successfully!', Color(0xFF1A4A6B));
      Navigator.pop(context, 'refresh');
    } catch (e) {
      dioErrorManager(e);
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> cancelBooking() async {
    setState(() => actionLoading = true);
    try {
      final dio = await MyDio().getDio();
      await dio.put('/bookings/$bookingId/cancel');
      if (!mounted) return;
      showSnack('Booking cancelled', Color(0xFF7D2D2D));
      Navigator.pop(context, 'refresh');
    } catch (e) {
      dioErrorManager(e);
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> extendStay(DateTime newToDate, TimeOfDay newToTime) async {
    final combined = DateTime(
      newToDate.year,
      newToDate.month,
      newToDate.day,
      newToTime.hour,
      newToTime.minute,
    );
    final currentTo = DateTime.parse(booking['to_date']).toLocal();
    if (!combined.isAfter(currentTo)) {
      showSnack(
        'New check-out must be after current check-out',
        Color(0xFF7D2D2D),
      );
      return;
    }
    setState(() => actionLoading = true);
    try {
      final dio = await MyDio().getDio();
      await dio.patch(
        '/bookings/$bookingId/extend',
        data: {'new_to_date': combined.toUtc().toIso8601String()},
      );
      if (!mounted) return;
      showSnack('Stay extended successfully!', Color(0xFF2D7D4F));
      Navigator.pop(context, 'refresh');
    } catch (e) {
      dioErrorManager(e);
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  void showConfirmDialog(
    String title,
    String body,
    String confirmText,
    Color confirmColor,
    VoidCallback onConfirm,
  ) {
    final width = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF131E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          body,
          style: TextStyle(color: Colors.white54, fontSize: width * 0.034),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Back', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(
              confirmText,
              style: TextStyle(
                color: confirmColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showExtendSheet() {
    DateTime? newToDate;
    TimeOfDay? newToTime;
    final currentTo = DateTime.parse(booking['to_date']).toLocal();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Color(0xFF0D1B2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFFC9A84C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_month_outlined,
                      color: Color(0xFFC9A84C),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extend your stay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Current check-out: ${formatDateTime(booking['to_date'])}',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'New check-out',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: currentTo.add(Duration(days: 1)),
                          firstDate: currentTo.add(Duration(days: 1)),
                          lastDate: currentTo.add(Duration(days: 365)),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Color(0xFFC9A84C),
                                surface: Color(0xFF0D1B2A),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null)
                          setSheetState(() => newToDate = picked);
                      },
                      child: Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Color(0xFF060E1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: newToDate != null
                                ? Color(0xFFC9A84C).withOpacity(0.4)
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: newToDate != null
                                  ? Color(0xFFC9A84C)
                                  : Colors.white24,
                              size: 14,
                            ),
                            SizedBox(width: 8),
                            Text(
                              newToDate != null
                                  ? formatDate(newToDate!)
                                  : 'Pick date',
                              style: TextStyle(
                                color: newToDate != null
                                    ? Colors.white
                                    : Colors.white30,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay(
                            hour: currentTo.hour,
                            minute: currentTo.minute,
                          ),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Color(0xFFC9A84C),
                                surface: Color(0xFF0D1B2A),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null)
                          setSheetState(() => newToTime = picked);
                      },
                      child: Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Color(0xFF060E1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: newToTime != null
                                ? Color(0xFFC9A84C).withOpacity(0.4)
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: newToTime != null
                                  ? Color(0xFFC9A84C)
                                  : Colors.white24,
                              size: 14,
                            ),
                            SizedBox(width: 8),
                            Text(
                              newToTime != null
                                  ? formatTime(newToTime!)
                                  : 'Time',
                              style: TextStyle(
                                color: newToTime != null
                                    ? Colors.white
                                    : Colors.white30,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (newToDate != null && newToTime != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color(0xFF060E1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFC9A84C),
                        size: 14,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Extending to ${formatDate(newToDate!)} at ${formatTime(newToTime!)}. Extra charges will be added to your total.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 20),
              GestureDetector(
                onTap: newToDate != null && newToTime != null
                    ? () {
                        Navigator.pop(ctx);
                        extendStay(newToDate!, newToTime!);
                      }
                    : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: newToDate != null && newToTime != null
                        ? Color(0xFFC9A84C)
                        : Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Confirm Extension',
                      style: TextStyle(
                        color: newToDate != null && newToTime != null
                            ? Colors.black
                            : Colors.white24,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed':
        return Color(0xFF2D7D4F);
      case 'checked_in':
        return Color(0xFF1A6B4A);
      case 'completed':
        return Color(0xFF1A4A6B);
      case 'cancelled':
        return Color(0xFF7D2D2D);
      default:
        return Color(0xFF4A4A4A);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
        return 'Checked In';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final duration = formatDuration(booking['from_date'], booking['to_date']);
    final isCheckedIn = status == 'checked_in';
    final isConfirmed = status == 'confirmed';
    final isDone = status == 'cancelled' || status == 'completed';

    return Scaffold(
      backgroundColor: Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Color(0xFF0A1628),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: width * 0.055,
          ),
        ),
        title: Text(
          'Manage booking',
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.048,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking card
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF131E2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              child: Image.asset(
                                'assets/images/portImages/port.jpg',
                                width: width * 0.28,
                                height: width * 0.32,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(width * 0.035),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            marinaName,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: width * 0.042,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                              status,
                                            ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: _statusColor(
                                                status,
                                              ).withOpacity(0.5),
                                            ),
                                          ),
                                          child: Text(
                                            _statusLabel(status),
                                            style: TextStyle(
                                              color: _statusColor(status),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.anchor,
                                          color: Colors.white38,
                                          size: width * 0.03,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          berthName,
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: width * 0.028,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: height * 0.012),
                                    Text(
                                      'Check-in',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: width * 0.026,
                                      ),
                                    ),
                                    Text(
                                      formatDateTime(booking['from_date']),
                                      style: TextStyle(
                                        color: Color(0xFFC9A84C),
                                        fontSize: width * 0.028,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Check-out',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: width * 0.026,
                                      ),
                                    ),
                                    Text(
                                      formatDateTime(booking['to_date']),
                                      style: TextStyle(
                                        color: Color(0xFFC9A84C),
                                        fontSize: width * 0.028,
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
                          padding: EdgeInsets.fromLTRB(
                            width * 0.04,
                            0,
                            width * 0.04,
                            width * 0.04,
                          ),
                          child: Row(
                            children: [
                              buildStat(
                                Icons.anchor,
                                'Berth',
                                berthName,
                                width,
                                height,
                              ),
                              Container(
                                width: 0.5,
                                height: height * 0.04,
                                color: Color(0xFF243044),
                              ),
                              buildStat(
                                Icons.access_time,
                                'Duration',
                                duration,
                                width,
                                height,
                              ),
                              Container(
                                width: 0.5,
                                height: height * 0.04,
                                color: Color(0xFF243044),
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
                      ],
                    ),
                  ),

                  SizedBox(height: height * 0.025),
                  Text(
                    'Booking actions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.042,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: height * 0.015),

                  Row(
                    children: [
                      buildActionBox(
                        isCheckedIn
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                        isCheckedIn ? 'Check out' : 'Check in',
                        isCheckedIn ? 'End your stay' : 'Start your stay',
                        width,
                        height,
                        isConfirmed || isCheckedIn
                            ? () {
                                if (isCheckedIn) {
                                  showConfirmDialog(
                                    'Check out?',
                                    'Your stay will be marked as completed.',
                                    'Yes, check out',
                                    Color(0xFFC9A84C),
                                    checkOut,
                                  );
                                } else {
                                  showConfirmDialog(
                                    'Check in?',
                                    'You are about to check in to $marinaName.',
                                    'Yes, check in',
                                    Color(0xFF2D7D4F),
                                    checkIn,
                                  );
                                }
                              }
                            : null,
                        disabled: isDone,
                      ),
                      SizedBox(width: width * 0.03),
                      buildActionBox(
                        Icons.calendar_month_outlined,
                        'Extend stay',
                        'Add more time',
                        width,
                        height,
                        isConfirmed || isCheckedIn ? showExtendSheet : null,
                        disabled: isDone,
                      ),
                      SizedBox(width: width * 0.03),
                      buildActionBox(
                        Icons.anchor,
                        'Change berth',
                        'Upgrade or change',
                        width,
                        height,
                        () => showSnack(
                          'Change berth coming soon',
                          Color(0xFF1A2A3A),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.025),
                  Text(
                    'Marina services',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.042,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: height * 0.015),
                  buildServiceRow(
                    Icons.phone_outlined,
                    'Contact marina',
                    'Call or chat with marina',
                    width,
                    height,
                    () => showSnack('Coming soon', Color(0xFF1A2A3A)),
                  ),
                  buildServiceRow(
                    Icons.info_outline,
                    'Marina information',
                    'Facilities, rules & more',
                    width,
                    height,
                    () => showSnack('Coming soon', Color(0xFF1A2A3A)),
                  ),
                  buildServiceRow(
                    Icons.navigation_outlined,
                    'Navigate to marina',
                    'Get directions',
                    width,
                    height,
                    () => showSnack('Coming soon', Color(0xFF1A2A3A)),
                  ),

                  SizedBox(height: height * 0.025),
                  Text(
                    'Booking settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.042,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: height * 0.015),
                  buildServiceRow(
                    Icons.receipt_outlined,
                    'Download invoice',
                    'View and download receipt',
                    width,
                    height,
                    () => showSnack('Coming soon', Color(0xFF1A2A3A)),
                  ),
                  buildServiceRow(
                    Icons.calendar_today_outlined,
                    'Add to calendar',
                    'Save booking to calendar',
                    width,
                    height,
                    () => showSnack('Coming soon', Color(0xFF1A2A3A)),
                  ),
                  buildServiceRow(
                    Icons.share_outlined,
                    'Share booking',
                    'Share itinerary with others',
                    width,
                    height,
                    () => showSnack('Coming soon', Color(0xFF1A2A3A)),
                  ),

                  SizedBox(height: height * 0.025),
                  Text(
                    'Danger zone',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: width * 0.042,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: height * 0.015),

                  GestureDetector(
                    onTap: () => showConfirmDialog(
                      'Cancel booking?',
                      'Cancelling your booking may result in a cancellation fee. Are you sure?',
                      'Yes, cancel',
                      Colors.red,
                      cancelBooking,
                    ),
                    child: Container(
                      margin: EdgeInsets.only(bottom: height * 0.03),
                      padding: EdgeInsets.all(width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(width * 0.025),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: width * 0.05,
                            ),
                          ),
                          SizedBox(width: width * 0.03),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cancel booking',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: width * 0.038,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Cancel your reservation',
                                style: TextStyle(
                                  color: Colors.red.withOpacity(0.6),
                                  fontSize: width * 0.028,
                                ),
                              ),
                            ],
                          ),
                          Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.red.withOpacity(0.6),
                            size: width * 0.035,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.02),
                ],
              ),
            ),

            if (actionLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFC9A84C),
                    strokeWidth: 2,
                  ),
                ),
              ),
          ],
        ),
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
                    fontSize: width * 0.024,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: width * 0.028,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActionBox(
    IconData icon,
    String title,
    String subtitle,
    double width,
    double height,
    VoidCallback? onTap, {
    bool disabled = false,
    String? hint,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: EdgeInsets.all(width * 0.035),
          decoration: BoxDecoration(
            color: disabled
                ? Color(0xFF131E2E).withOpacity(0.5)
                : Color(0xFF131E2E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  color: disabled
                      ? Colors.white.withOpacity(0.05)
                      : Color(0xFFC9A84C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: disabled ? Colors.white24 : Color(0xFFC9A84C),
                  size: width * 0.055,
                ),
              ),
              SizedBox(height: height * 0.01),
              Text(
                title,
                style: TextStyle(
                  color: disabled ? Colors.white24 : Colors.white,
                  fontSize: width * 0.03,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                hint ?? subtitle,
                style: TextStyle(
                  color: disabled ? Colors.white12 : Colors.white38,
                  fontSize: width * 0.022,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildServiceRow(
    IconData icon,
    String title,
    String subtitle,
    double width,
    double height,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.01),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Color(0xFF131E2E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: Color(0xFFC9A84C).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Color(0xFFC9A84C), size: width * 0.045),
            ),
            SizedBox(width: width * 0.03),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.036,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: width * 0.028,
                  ),
                ),
              ],
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: width * 0.035,
            ),
          ],
        ),
      ),
    );
  }
}

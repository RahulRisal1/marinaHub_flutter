import 'package:flutter/material.dart';
import 'package:marinahub/dio/myDio.dart';

class ManageBookingScreen extends StatelessWidget {
  final dynamic booking;

  const ManageBookingScreen({super.key, required this.booking});

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

  Future<void> cancelBooking(BuildContext context) async {
    try {
      final dio = await MyDio().getDio();
      await dio.put('/bookings/${booking['booking_id']}/cancel');
      Navigator.pop(context, 'refresh');
    } catch (e) {
      debugPrint('Cancel error: $e');
    }
  }

  Future<void> completeBooking(BuildContext context) async {
    try {
      final dio = await MyDio().getDio();
      await dio.put('/bookings/${booking['booking_id']}/complete');
      Navigator.pop(context, 'refresh');
    } catch (e) {
      debugPrint('Complete error: $e');
    }
  }

  void showCancelDialog(BuildContext context, double width) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel booking?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Please note that cancelling your booking may result in a cancellation fee. Are you sure you want to cancel?',
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
              cancelBooking(context);
            },
            child: Text(
              'Yes, cancel',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void showCheckoutDialog(BuildContext context, double width) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Check out?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to check out? Your stay will be marked as completed.',
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
              completeBooking(context);
            },
            child: Text(
              'Yes, check out',
              style: TextStyle(
                color: const Color(0xFFC9A84C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final nights = calculateNights(booking['from_date'], booking['to_date']);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF131E2E),
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
                                  height: width * 0.28,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(width * 0.035),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking['marina_name'] ?? '',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: width * 0.042,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
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
                                      SizedBox(height: height * 0.015),
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Check-in',
                                                style: TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: width * 0.026,
                                                ),
                                              ),
                                              Text(
                                                formatDate(
                                                  booking['from_date'],
                                                ),
                                                style: TextStyle(
                                                  color: const Color(
                                                    0xFFC9A84C,
                                                  ),
                                                  fontSize: width * 0.028,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: width * 0.05),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
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
                                                  color: const Color(
                                                    0xFFC9A84C,
                                                  ),
                                                  fontSize: width * 0.028,
                                                  fontWeight: FontWeight.w500,
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
                                  'Total price',
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
                          Icons.qr_code_outlined,
                          'Check in',
                          'Start check-in',
                          width,
                          height,
                          () {},
                        ),
                        SizedBox(width: width * 0.03),
                        buildActionBox(
                          Icons.calendar_month_outlined,
                          'Extend stay',
                          'Add more nights',
                          width,
                          height,
                          () {},
                        ),
                        SizedBox(width: width * 0.03),
                        buildActionBox(
                          Icons.anchor,
                          'Change berth',
                          'Upgrade or change',
                          width,
                          height,
                          () {},
                        ),
                      ],
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
                      onTap: () => showCheckoutDialog(context, width),
                      child: Container(
                        margin: EdgeInsets.only(bottom: height * 0.012),
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A84C).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFC9A84C).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(width * 0.025),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFC9A84C,
                                ).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.logout,
                                color: const Color(0xFFC9A84C),
                                size: width * 0.05,
                              ),
                            ),
                            SizedBox(width: width * 0.03),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Check out',
                                  style: TextStyle(
                                    color: const Color(0xFFC9A84C),
                                    fontSize: width * 0.038,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Mark your stay as completed',
                                  style: TextStyle(
                                    color: const Color(
                                      0xFFC9A84C,
                                    ).withOpacity(0.6),
                                    fontSize: width * 0.028,
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: const Color(0xFFC9A84C).withOpacity(0.6),
                              size: width * 0.035,
                            ),
                          ],
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () => showCancelDialog(context, width),
                      child: Container(
                        margin: EdgeInsets.only(bottom: height * 0.03),
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
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

                    SizedBox(height: height * 0.015),
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
                      () {},
                    ),
                    buildServiceRow(
                      Icons.info_outline,
                      'Marina information',
                      'Facilities, rules & more',
                      width,
                      height,
                      () {},
                    ),
                    buildServiceRow(
                      Icons.navigation_outlined,
                      'Navigate to marina',
                      'Get directions',
                      width,
                      height,
                      () {},
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
                      () {},
                    ),
                    buildServiceRow(
                      Icons.calendar_today_outlined,
                      'Add to calendar',
                      'Save booking to calendar',
                      width,
                      height,
                      () {},
                    ),
                    buildServiceRow(
                      Icons.share_outlined,
                      'Share booking',
                      'Share itinerary with others',
                      width,
                      height,
                      () {},
                    ),

                    SizedBox(height: height * 0.025),
                  ],
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
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(width * 0.035),
          decoration: BoxDecoration(
            color: const Color(0xFF131E2E),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFC9A84C),
                  size: width * 0.055,
                ),
              ),
              SizedBox(height: height * 0.01),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.03,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: width * 0.024,
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
          color: const Color(0xFF131E2E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: const Color(0xFFC9A84C).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFC9A84C),
                size: width * 0.045,
              ),
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

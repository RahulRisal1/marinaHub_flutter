// import 'package:flutter/material.dart';
// import 'package:dio/dio.dart';
// import 'package:marinahub/dio/myDio.dart';
// import 'package:marinahub/dio/dioErrorManager.dart';
// import 'package:marinahub/utils/colors.dart';

// class AdminDashboard extends StatefulWidget {
//   AdminDashboard({super.key});

//   @override
//   State<AdminDashboard> createState() => _AdminDashboardState();
// }

// class _AdminDashboardState extends State<AdminDashboard> {
//   int selectedIndex = 0;

//   // Data
//   List marinas = [];
//   List berths = [];
//   List bookings = [];
//   List users = [];
//   List orders = [];

//   // Loading states
//   bool loadingMarinas = true;
//   bool loadingBerths = true;
//   bool loadingBookings = true;
//   bool loadingUsers = true;
//   bool loadingOrders = true;

//   List<Map<String, dynamic>> navItems = [
//     {
//       'icon': Icons.dashboard_outlined,
//       'activeIcon': Icons.dashboard,
//       'label': 'Overview',
//     },
//     {
//       'icon': Icons.location_on_outlined,
//       'activeIcon': Icons.location_on,
//       'label': 'Marinas',
//     },
//     {
//       'icon': Icons.directions_boat_outlined,
//       'activeIcon': Icons.directions_boat,
//       'label': 'Berths',
//     },
//     {
//       'icon': Icons.calendar_today_outlined,
//       'activeIcon': Icons.calendar_today,
//       'label': 'Bookings',
//     },
//     {
//       'icon': Icons.build_outlined,
//       'activeIcon': Icons.build,
//       'label': 'Services',
//     },
//     {
//       'icon': Icons.receipt_long_outlined,
//       'activeIcon': Icons.receipt_long,
//       'label': 'Orders',
//     },
//     {
//       'icon': Icons.people_outline,
//       'activeIcon': Icons.people,
//       'label': 'Users',
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     loadAll();
//   }

//   Future<void> loadAll() async {
//     loadMarinas();
//     loadBerths();
//     loadBookings();
//     loadUsers();
//     loadOrders();
//   }

//   Future<void> loadMarinas() async {
//     setState(() => loadingMarinas = true);
//     try {
//       final dio = await MyDio().getDio();
//       final res = await dio.get('/marinas');
//       setState(() => marinas = res.data['marinas'] ?? []);
//     } on DioException catch (e) {
//       dioErrorManager(e);
//     } finally {
//       setState(() => loadingMarinas = false);
//     }
//   }

//   Future<void> loadBerths() async {
//     setState(() => loadingBerths = true);
//     try {
//       final dio = await MyDio().getDio();
//       final res = await dio.get('/berths');
//       setState(() => berths = res.data['berths'] ?? []);
//     } on DioException catch (e) {
//       dioErrorManager(e);
//     } finally {
//       setState(() => loadingBerths = false);
//     }
//   }

//   Future<void> loadBookings() async {
//     setState(() => loadingBookings = true);
//     try {
//       final dio = await MyDio().getDio();
//       final res = await dio.get('/bookings/all');
//       setState(() => bookings = res.data['bookings'] ?? []);
//     } on DioException catch (e) {
//       dioErrorManager(e);
//     } finally {
//       setState(() => loadingBookings = false);
//     }
//   }

//   Future<void> loadUsers() async {
//     setState(() => loadingUsers = true);
//     try {
//       final dio = await MyDio().getDio();
//       final res = await dio.get('/users/all');
//       setState(() => users = res.data['users'] ?? []);
//     } on DioException catch (e) {
//       dioErrorManager(e);
//     } finally {
//       setState(() => loadingUsers = false);
//     }
//   }

//   Future<void> loadOrders() async {
//     setState(() => loadingOrders = true);
//     try {
//       final dio = await MyDio().getDio();
//       final res = await dio.get('/service-orders/all');
//       setState(() => orders = res.data['orders'] ?? []);
//     } on DioException catch (e) {
//       dioErrorManager(e);
//     } finally {
//       setState(() => loadingOrders = false);
//     }
//   }

//   // Derived counts
//   int get activeBookings => bookings
//       .where((b) => b['status'] == 'confirmed' || b['status'] == 'checked_in')
//       .length;
//   int get pendingOrders => orders.where((o) => o['status'] == 'pending').length;
//   double get totalRevenue => bookings.fold(
//     0.0,
//     (sum, b) => sum + ((b['total_price'] ?? 0) as num).toDouble(),
//   );

//   String formatRevenue(double amount) {
//     if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
//     if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
//     return amount.toStringAsFixed(0);
//   }

//   Widget buildStatValue(bool loading, String value, Color color) {
//     if (loading) {
//       return SizedBox(
//         width: 20,
//         height: 20,
//         child: CircularProgressIndicator(strokeWidth: 2, color: color),
//       );
//     }
//     return Text(
//       value,
//       style: TextStyle(
//         color: textPrimary,
//         fontSize: 20,
//         fontWeight: FontWeight.w700,
//       ),
//     );
//   }

//   Widget buildStatCard(
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//     bool loading,
//   ) {
//     return Container(
//       padding: EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: navyCard,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: divider, width: 0.8),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 34,
//                 height: 34,
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(icon, color: color, size: 18),
//               ),
//               Spacer(),
//               Icon(Icons.trending_up, color: color.withOpacity(0.5), size: 14),
//             ],
//           ),
//           SizedBox(height: 10),
//           loading
//               ? SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: color,
//                   ),
//                 )
//               : Text(
//                   value,
//                   style: TextStyle(
//                     color: textPrimary,
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//           SizedBox(height: 2),
//           Text(
//             label,
//             style: TextStyle(color: textSecondary, fontSize: 11),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildOverview(double width) {
//     bool isWide = width > 600;
//     int crossCount = isWide ? 3 : 2;

//     List<Map<String, dynamic>> stats = [
//       {
//         'label': 'Total Marinas',
//         'value': '${marinas.length}',
//         'icon': Icons.location_on_outlined,
//         'color': accentBlue,
//         'loading': loadingMarinas,
//       },
//       {
//         'label': 'Total Berths',
//         'value': '${berths.length}',
//         'icon': Icons.directions_boat_outlined,
//         'color': accentGreen,
//         'loading': loadingBerths,
//       },
//       {
//         'label': 'Active Bookings',
//         'value': '$activeBookings',
//         'icon': Icons.calendar_today_outlined,
//         'color': gold,
//         'loading': loadingBookings,
//       },
//       {
//         'label': 'Pending Orders',
//         'value': '$pendingOrders',
//         'icon': Icons.receipt_long_outlined,
//         'color': Color(0xFF9B59B6),
//         'loading': loadingOrders,
//       },
//       {
//         'label': 'Total Users',
//         'value': '${users.length}',
//         'icon': Icons.people_outline,
//         'color': danger,
//         'loading': loadingUsers,
//       },
//       {
//         'label': 'Total Revenue',
//         'value': '${formatRevenue(totalRevenue)} NOK',
//         'icon': Icons.bar_chart_outlined,
//         'color': accentGreen,
//         'loading': loadingBookings,
//       },
//     ];

//     return RefreshIndicator(
//       color: gold,
//       backgroundColor: navyCard,
//       onRefresh: loadAll,
//       child: SingleChildScrollView(
//         physics: AlwaysScrollableScrollPhysics(),
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Admin Portal',
//                         style: TextStyle(color: textSecondary, fontSize: 12),
//                       ),
//                       SizedBox(height: 2),
//                       RichText(
//                         text: TextSpan(
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.w700,
//                             color: textPrimary,
//                           ),
//                           children: [
//                             TextSpan(text: 'Marina'),
//                             TextSpan(
//                               text: 'Hub',
//                               style: TextStyle(color: gold),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: accentGreen.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: accentGreen.withOpacity(0.3)),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: 6,
//                         height: 6,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: accentGreen,
//                         ),
//                       ),
//                       SizedBox(width: 5),
//                       Text(
//                         'Live',
//                         style: TextStyle(
//                           color: accentGreen,
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             SizedBox(height: 20),

//             Text(
//               'AT A GLANCE',
//               style: TextStyle(
//                 color: textSecondary,
//                 fontSize: 10,
//                 letterSpacing: 2,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             SizedBox(height: 10),

//             GridView.builder(
//               shrinkWrap: true,
//               physics: NeverScrollableScrollPhysics(),
//               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: crossCount,
//                 crossAxisSpacing: 10,
//                 mainAxisSpacing: 10,
//                 childAspectRatio: 1.4,
//               ),
//               itemCount: stats.length,
//               itemBuilder: (context, i) {
//                 Map<String, dynamic> s = stats[i];
//                 return buildStatCard(
//                   s['label'],
//                   s['value'],
//                   s['icon'],
//                   s['color'],
//                   s['loading'],
//                 );
//               },
//             ),

//             SizedBox(height: 20),

//             // Recent bookings
//             Row(
//               children: [
//                 Text(
//                   'RECENT BOOKINGS',
//                   style: TextStyle(
//                     color: textSecondary,
//                     fontSize: 10,
//                     letterSpacing: 2,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Spacer(),
//                 GestureDetector(
//                   onTap: () => setState(() => selectedIndex = 3),
//                   child: Text(
//                     'See all',
//                     style: TextStyle(color: gold, fontSize: 12),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 10),
//             loadingBookings
//                 ? Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(20),
//                       child: CircularProgressIndicator(color: gold),
//                     ),
//                   )
//                 : bookings.isEmpty
//                 ? buildEmpty('No bookings yet')
//                 : Container(
//                     decoration: BoxDecoration(
//                       color: navyCard,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: divider, width: 0.8),
//                     ),
//                     child: Column(
//                       children: bookings.take(5).toList().asMap().entries.map((
//                         entry,
//                       ) {
//                         int i = entry.key;
//                         Map b = entry.value;
//                         String status = b['status'] ?? 'unknown';
//                         Color statusColor = status == 'confirmed'
//                             ? accentGreen
//                             : status == 'checked_in'
//                             ? accentBlue
//                             : status == 'cancelled'
//                             ? danger
//                             : textSecondary;
//                         return Column(
//                           children: [
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: 14,
//                                 vertical: 11,
//                               ),
//                               child: Row(
//                                 children: [
//                                   Container(
//                                     width: 32,
//                                     height: 32,
//                                     decoration: BoxDecoration(
//                                       color: statusColor.withOpacity(0.12),
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: Icon(
//                                       Icons.anchor,
//                                       color: statusColor,
//                                       size: 15,
//                                     ),
//                                   ),
//                                   SizedBox(width: 10),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           b['marina']?['name'] ??
//                                               b['marina_id'] ??
//                                               'Marina',
//                                           style: TextStyle(
//                                             color: textPrimary,
//                                             fontSize: 13,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                           maxLines: 1,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                         Text(
//                                           b['berth']?['name'] ??
//                                               'Berth · ${(b['total_price'] ?? 0)} NOK',
//                                           style: TextStyle(
//                                             color: textSecondary,
//                                             fontSize: 11,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   Container(
//                                     padding: EdgeInsets.symmetric(
//                                       horizontal: 8,
//                                       vertical: 3,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: statusColor.withOpacity(0.1),
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     child: Text(
//                                       status,
//                                       style: TextStyle(
//                                         color: statusColor,
//                                         fontSize: 10,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             if (i < 4)
//                               Divider(
//                                 height: 0,
//                                 thickness: 0.5,
//                                 color: divider,
//                               ),
//                           ],
//                         );
//                       }).toList(),
//                     ),
//                   ),

//             SizedBox(height: 20),

//             // Recent users
//             Row(
//               children: [
//                 Text(
//                   'RECENT USERS',
//                   style: TextStyle(
//                     color: textSecondary,
//                     fontSize: 10,
//                     letterSpacing: 2,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Spacer(),
//                 GestureDetector(
//                   onTap: () => setState(() => selectedIndex = 6),
//                   child: Text(
//                     'See all',
//                     style: TextStyle(color: gold, fontSize: 12),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 10),
//             loadingUsers
//                 ? Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(20),
//                       child: CircularProgressIndicator(color: gold),
//                     ),
//                   )
//                 : users.isEmpty
//                 ? buildEmpty('No users yet')
//                 : Container(
//                     decoration: BoxDecoration(
//                       color: navyCard,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: divider, width: 0.8),
//                     ),
//                     child: Column(
//                       children: users.take(4).toList().asMap().entries.map((
//                         entry,
//                       ) {
//                         int i = entry.key;
//                         Map u = entry.value;
//                         return Column(
//                           children: [
//                             Padding(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: 14,
//                                 vertical: 11,
//                               ),
//                               child: Row(
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 16,
//                                     backgroundColor: gold.withOpacity(0.15),
//                                     child: Text(
//                                       (u['name'] ?? 'U')
//                                           .toString()
//                                           .substring(0, 1)
//                                           .toUpperCase(),
//                                       style: TextStyle(
//                                         color: gold,
//                                         fontSize: 13,
//                                         fontWeight: FontWeight.w700,
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(width: 10),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           u['name'] ?? 'Unknown',
//                                           style: TextStyle(
//                                             color: textPrimary,
//                                             fontSize: 13,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                         Text(
//                                           u['email'] ?? '',
//                                           style: TextStyle(
//                                             color: textSecondary,
//                                             fontSize: 11,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   Container(
//                                     padding: EdgeInsets.symmetric(
//                                       horizontal: 8,
//                                       vertical: 3,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color:
//                                           (u['role'] == 'admin'
//                                                   ? gold
//                                                   : accentBlue)
//                                               .withOpacity(0.1),
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     child: Text(
//                                       u['role'] ?? 'boater',
//                                       style: TextStyle(
//                                         color: u['role'] == 'admin'
//                                             ? gold
//                                             : accentBlue,
//                                         fontSize: 10,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             if (i < 3)
//                               Divider(
//                                 height: 0,
//                                 thickness: 0.5,
//                                 color: divider,
//                               ),
//                           ],
//                         );
//                       }).toList(),
//                     ),
//                   ),

//             SizedBox(height: 24),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildMarinasList() {
//     return RefreshIndicator(
//       color: gold,
//       backgroundColor: navyCard,
//       onRefresh: loadMarinas,
//       child: loadingMarinas
//           ? Center(child: CircularProgressIndicator(color: gold))
//           : marinas.isEmpty
//           ? buildEmpty('No marinas found')
//           : ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: marinas.length,
//               itemBuilder: (context, i) {
//                 Map marina = marinas[i];
//                 return Container(
//                   margin: EdgeInsets.only(bottom: 10),
//                   padding: EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: navyCard,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: divider, width: 0.8),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 44,
//                         height: 44,
//                         decoration: BoxDecoration(
//                           color: accentBlue.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Icon(
//                           Icons.location_on,
//                           color: accentBlue,
//                           size: 22,
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               marina['name'] ?? '',
//                               style: TextStyle(
//                                 color: textPrimary,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             SizedBox(height: 2),
//                             Text(
//                               marina['location'] ?? '',
//                               style: TextStyle(
//                                 color: textSecondary,
//                                 fontSize: 12,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             SizedBox(height: 4),
//                             Row(
//                               children: [
//                                 Icon(Icons.anchor, color: gold, size: 12),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   '${marina['totalBerths'] ?? 0} berths',
//                                   style: TextStyle(color: gold, fontSize: 11),
//                                 ),
//                                 SizedBox(width: 12),
//                                 if (marina['cheapestPrice'] != null) ...[
//                                   Icon(
//                                     Icons.payments_outlined,
//                                     color: textSecondary,
//                                     size: 12,
//                                   ),
//                                   SizedBox(width: 4),
//                                   Text(
//                                     'From ${marina['cheapestPrice']} NOK/night',
//                                     style: TextStyle(
//                                       color: textSecondary,
//                                       fontSize: 11,
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       Icon(
//                         Icons.arrow_forward_ios,
//                         color: textSecondary,
//                         size: 14,
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget buildBerthsList() {
//     return RefreshIndicator(
//       color: gold,
//       backgroundColor: navyCard,
//       onRefresh: loadBerths,
//       child: loadingBerths
//           ? Center(child: CircularProgressIndicator(color: gold))
//           : berths.isEmpty
//           ? buildEmpty('No berths found')
//           : ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: berths.length,
//               itemBuilder: (context, i) {
//                 Map berth = berths[i];
//                 bool available = berth['is_available'] ?? true;
//                 return Container(
//                   margin: EdgeInsets.only(bottom: 10),
//                   padding: EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: navyCard,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: divider, width: 0.8),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 44,
//                         height: 44,
//                         decoration: BoxDecoration(
//                           color: (available ? accentGreen : danger).withOpacity(
//                             0.1,
//                           ),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Icon(
//                           Icons.directions_boat,
//                           color: available ? accentGreen : danger,
//                           size: 22,
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               berth['name'] ?? '',
//                               style: TextStyle(
//                                 color: textPrimary,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             SizedBox(height: 2),
//                             Text(
//                               '${berth['length']}m × ${berth['width']}m · depth ${berth['depth']}m',
//                               style: TextStyle(
//                                 color: textSecondary,
//                                 fontSize: 12,
//                               ),
//                             ),
//                             SizedBox(height: 4),
//                             Text(
//                               '${berth['price_per_night']} NOK/night · ${berth['price_per_hour']} NOK/hr',
//                               style: TextStyle(color: gold, fontSize: 11),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: (available ? accentGreen : danger).withOpacity(
//                             0.1,
//                           ),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           available ? 'Available' : 'Booked',
//                           style: TextStyle(
//                             color: available ? accentGreen : danger,
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget buildBookingsList() {
//     return RefreshIndicator(
//       color: gold,
//       backgroundColor: navyCard,
//       onRefresh: loadBookings,
//       child: loadingBookings
//           ? Center(child: CircularProgressIndicator(color: gold))
//           : bookings.isEmpty
//           ? buildEmpty('No bookings found')
//           : ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: bookings.length,
//               itemBuilder: (context, i) {
//                 Map b = bookings[i];
//                 String status = b['status'] ?? 'unknown';
//                 Color statusColor = status == 'confirmed'
//                     ? accentGreen
//                     : status == 'checked_in'
//                     ? accentBlue
//                     : status == 'cancelled'
//                     ? danger
//                     : status == 'completed'
//                     ? gold
//                     : textSecondary;
//                 return Container(
//                   margin: EdgeInsets.only(bottom: 10),
//                   padding: EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: navyCard,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: divider, width: 0.8),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               b['marina']?['name'] ?? 'Marina',
//                               style: TextStyle(
//                                 color: textPrimary,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 3,
//                             ),
//                             decoration: BoxDecoration(
//                               color: statusColor.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: Text(
//                               status,
//                               style: TextStyle(
//                                 color: statusColor,
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 6),
//                       Row(
//                         children: [
//                           Icon(Icons.anchor, color: textSecondary, size: 12),
//                           SizedBox(width: 4),
//                           Text(
//                             b['berth']?['name'] ?? 'Berth',
//                             style: TextStyle(
//                               color: textSecondary,
//                               fontSize: 12,
//                             ),
//                           ),
//                           SizedBox(width: 12),
//                           Icon(
//                             Icons.person_outline,
//                             color: textSecondary,
//                             size: 12,
//                           ),
//                           SizedBox(width: 4),
//                           Expanded(
//                             child: Text(
//                               b['user']?['name'] ??
//                                   b['user']?['email'] ??
//                                   'User',
//                               style: TextStyle(
//                                 color: textSecondary,
//                                 fontSize: 12,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 4),
//                       Row(
//                         children: [
//                           Icon(Icons.payments_outlined, color: gold, size: 12),
//                           SizedBox(width: 4),
//                           Text(
//                             '${b['total_price'] ?? 0} NOK',
//                             style: TextStyle(
//                               color: gold,
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget buildUsersList() {
//     return RefreshIndicator(
//       color: gold,
//       backgroundColor: navyCard,
//       onRefresh: loadUsers,
//       child: loadingUsers
//           ? Center(child: CircularProgressIndicator(color: gold))
//           : users.isEmpty
//           ? buildEmpty('No users found')
//           : ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: users.length,
//               itemBuilder: (context, i) {
//                 Map u = users[i];
//                 return Container(
//                   margin: EdgeInsets.only(bottom: 10),
//                   padding: EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: navyCard,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: divider, width: 0.8),
//                   ),
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 20,
//                         backgroundColor: gold.withOpacity(0.15),
//                         child: Text(
//                           (u['name'] ?? 'U')
//                               .toString()
//                               .substring(0, 1)
//                               .toUpperCase(),
//                           style: TextStyle(
//                             color: gold,
//                             fontSize: 15,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               u['name'] ?? 'Unknown',
//                               style: TextStyle(
//                                 color: textPrimary,
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             Text(
//                               u['email'] ?? '',
//                               style: TextStyle(
//                                 color: textSecondary,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: (u['role'] == 'admin' ? gold : accentBlue)
//                               .withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           u['role'] ?? 'boater',
//                           style: TextStyle(
//                             color: u['role'] == 'admin' ? gold : accentBlue,
//                             fontSize: 11,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget buildOrdersList() {
//     return RefreshIndicator(
//       color: gold,
//       backgroundColor: navyCard,
//       onRefresh: loadOrders,
//       child: loadingOrders
//           ? Center(child: CircularProgressIndicator(color: gold))
//           : orders.isEmpty
//           ? buildEmpty('No orders found')
//           : ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: orders.length,
//               itemBuilder: (context, i) {
//                 Map o = orders[i];
//                 String status = o['status'] ?? 'pending';
//                 Color statusColor = status == 'completed'
//                     ? accentGreen
//                     : status == 'in_progress'
//                     ? accentBlue
//                     : status == 'accepted'
//                     ? gold
//                     : status == 'cancelled'
//                     ? danger
//                     : textSecondary;
//                 return Container(
//                   margin: EdgeInsets.only(bottom: 10),
//                   padding: EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: navyCard,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: divider, width: 0.8),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 44,
//                         height: 44,
//                         decoration: BoxDecoration(
//                           color: statusColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Icon(
//                           Icons.receipt_long,
//                           color: statusColor,
//                           size: 20,
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               o['order_number'] ?? '',
//                               style: TextStyle(
//                                 color: textPrimary,
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             SizedBox(height: 2),
//                             Text(
//                               o['service']?['name'] ?? 'Service',
//                               style: TextStyle(
//                                 color: textSecondary,
//                                 fontSize: 12,
//                               ),
//                             ),
//                             SizedBox(height: 2),
//                             Text(
//                               '${o['total_price'] ?? 0} NOK · qty ${o['quantity'] ?? 1}',
//                               style: TextStyle(color: gold, fontSize: 11),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: statusColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Text(
//                           status,
//                           style: TextStyle(
//                             color: statusColor,
//                             fontSize: 10,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget buildComingSoon(String label, IconData icon) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 64,
//             height: 64,
//             decoration: BoxDecoration(
//               color: navyCard,
//               shape: BoxShape.circle,
//               border: Border.all(color: divider),
//             ),
//             child: Icon(icon, color: gold, size: 28),
//           ),
//           SizedBox(height: 14),
//           Text(
//             label,
//             style: TextStyle(
//               color: textPrimary,
//               fontSize: 16,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           SizedBox(height: 4),
//           Text(
//             'Coming soon',
//             style: TextStyle(color: textSecondary, fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildEmpty(String message) {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.all(40),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.inbox_outlined, color: textSecondary, size: 40),
//             SizedBox(height: 12),
//             Text(message, style: TextStyle(color: textSecondary, fontSize: 14)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildSectionHeader(String title) {
//     return Padding(
//       padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
//       child: Text(
//         title,
//         style: TextStyle(
//           color: textPrimary,
//           fontSize: 18,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//     );
//   }

//   Widget buildBody(double width) {
//     switch (selectedIndex) {
//       case 0:
//         return buildOverview(width);
//       case 1:
//         return Column(
//           children: [
//             buildSectionHeader('Marinas'),
//             SizedBox(height: 4),
//             Expanded(child: buildMarinasList()),
//           ],
//         );
//       case 2:
//         return Column(
//           children: [
//             buildSectionHeader('Berths'),
//             SizedBox(height: 4),
//             Expanded(child: buildBerthsList()),
//           ],
//         );
//       case 3:
//         return Column(
//           children: [
//             buildSectionHeader('Bookings'),
//             SizedBox(height: 4),
//             Expanded(child: buildBookingsList()),
//           ],
//         );
//       case 4:
//         return buildComingSoon('Services', Icons.build_outlined);
//       case 5:
//         return Column(
//           children: [
//             buildSectionHeader('Orders'),
//             SizedBox(height: 4),
//             Expanded(child: buildOrdersList()),
//           ],
//         );
//       case 6:
//         return Column(
//           children: [
//             buildSectionHeader('Users'),
//             SizedBox(height: 4),
//             Expanded(child: buildUsersList()),
//           ],
//         );
//       default:
//         return buildOverview(width);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     double width = MediaQuery.of(context).size.width;

//     return Scaffold(
//       backgroundColor: navy,
//       body: SafeArea(
//         child: Row(
//           children: [
//             // Side nav rail
//             Container(
//               width: 64,
//               decoration: BoxDecoration(
//                 color: navyCard,
//                 border: Border(right: BorderSide(color: divider, width: 0.8)),
//               ),
//               child: Column(
//                 children: [
//                   SizedBox(height: 14),
//                   Container(
//                     width: 36,
//                     height: 36,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       border: Border.all(
//                         color: gold.withOpacity(0.5),
//                         width: 1,
//                       ),
//                       color: navy,
//                     ),
//                     child: Icon(Icons.anchor, color: gold, size: 18),
//                   ),
//                   SizedBox(height: 16),
//                   Divider(
//                     thickness: 0.5,
//                     color: divider,
//                     indent: 10,
//                     endIndent: 10,
//                   ),
//                   SizedBox(height: 6),
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: navItems.length,
//                       itemBuilder: (context, i) {
//                         bool isSelected = selectedIndex == i;
//                         return GestureDetector(
//                           onTap: () => setState(() => selectedIndex = i),
//                           child: Container(
//                             margin: EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             padding: EdgeInsets.symmetric(vertical: 8),
//                             decoration: BoxDecoration(
//                               color: isSelected
//                                   ? gold.withOpacity(0.12)
//                                   : Colors.transparent,
//                               borderRadius: BorderRadius.circular(10),
//                               border: isSelected
//                                   ? Border.all(
//                                       color: gold.withOpacity(0.25),
//                                       width: 0.8,
//                                     )
//                                   : null,
//                             ),
//                             child: Column(
//                               children: [
//                                 Icon(
//                                   isSelected
//                                       ? navItems[i]['activeIcon'] as IconData
//                                       : navItems[i]['icon'] as IconData,
//                                   color: isSelected ? gold : textSecondary,
//                                   size: 20,
//                                 ),
//                                 SizedBox(height: 3),
//                                 Text(
//                                   navItems[i]['label'] as String,
//                                   style: TextStyle(
//                                     color: isSelected ? gold : textSecondary,
//                                     fontSize: 8,
//                                     fontWeight: isSelected
//                                         ? FontWeight.w600
//                                         : FontWeight.w400,
//                                   ),
//                                   textAlign: TextAlign.center,
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   Divider(
//                     thickness: 0.5,
//                     color: divider,
//                     indent: 10,
//                     endIndent: 10,
//                   ),
//                   GestureDetector(
//                     onTap: () => Navigator.of(context).pop(),
//                     child: Padding(
//                       padding: EdgeInsets.symmetric(vertical: 14),
//                       child: Column(
//                         children: [
//                           Icon(Icons.logout, color: danger, size: 20),
//                           SizedBox(height: 3),
//                           Text(
//                             'Logout',
//                             style: TextStyle(color: danger, fontSize: 8),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                 ],
//               ),
//             ),

//             // Main content
//             Expanded(child: buildBody(width - 64)),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:marinahub/adminscreens/adminDashboard/adminBerthPage.dart';
import 'package:marinahub/adminscreens/adminDashboard/adminBookingPage.dart';
import 'package:marinahub/adminscreens/adminDashboard/adminMarinasPage.dart';
import 'package:marinahub/adminscreens/adminDashboard/adminOrderPage.dart';
import 'package:marinahub/adminscreens/adminDashboard/adminOverviewPage.dart';
import 'package:marinahub/adminscreens/adminDashboard/adminServicePage.dart';
import 'package:marinahub/adminscreens/adminDashboard/adminUserPage.dart';
import 'package:marinahub/utils/colors.dart';

class AdminDashboard extends StatefulWidget {
  AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  List<Widget> pages = [
    AdminOverviewPage(),
    AdminMarinasPage(),
    AdminBerthsPage(),
    AdminBookingsPage(),
    AdminServicesPage(),
    AdminOrdersPage(),
    AdminUsersPage(),
  ];

  List<Map<String, dynamic>> navItems = [
    {
      'icon': Icons.dashboard_outlined,
      'activeIcon': Icons.dashboard,
      'label': 'Overview',
    },
    {
      'icon': Icons.location_on_outlined,
      'activeIcon': Icons.location_on,
      'label': 'Marinas',
    },
    {
      'icon': Icons.directions_boat_outlined,
      'activeIcon': Icons.directions_boat,
      'label': 'Berths',
    },
    {
      'icon': Icons.calendar_today_outlined,
      'activeIcon': Icons.calendar_today,
      'label': 'Bookings',
    },
    {
      'icon': Icons.build_outlined,
      'activeIcon': Icons.build,
      'label': 'Services',
    },
    {
      'icon': Icons.receipt_long_outlined,
      'activeIcon': Icons.receipt_long,
      'label': 'Orders',
    },
    {
      'icon': Icons.people_outline,
      'activeIcon': Icons.people,
      'label': 'Users',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navyCard,
          border: Border(top: BorderSide(color: divider, width: 0.8)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: navItems.asMap().entries.map((entry) {
                int i = entry.key;
                Map<String, dynamic> item = entry.value;
                bool isSelected = selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected
                              ? item['activeIcon'] as IconData
                              : item['icon'] as IconData,
                          color: isSelected ? gold : textSecondary,
                          size: 20,
                        ),
                        SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: isSelected ? gold : textSecondary,
                            fontSize: 9,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

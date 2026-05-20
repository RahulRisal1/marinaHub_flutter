// import 'package:flutter/material.dart';
// import 'package:dio/dio.dart';
// import 'package:marinahub/dio/myDio.dart';
// import 'package:marinahub/dio/dioErrorManager.dart';
// import 'package:marinahub/utils/colors.dart';

// class AdminServicesPage extends StatefulWidget {
//   AdminServicesPage({super.key});

//   @override
//   State<AdminServicesPage> createState() => _AdminServicesPageState();
// }

// class _AdminServicesPageState extends State<AdminServicesPage> {
//   List marinas = [];
//   List services = [];
//   List filteredServices = [];
//   bool loadingMarinas = true;
//   bool loadingServices = false;
//   Map? selectedMarina;
//   String activeFilter = 'all'; // all, active, inactive
//   TextEditingController searchCtrl = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     loadMarinas();
//     searchCtrl.addListener(applyFilter);
//   }

//   @override
//   void dispose() {
//     searchCtrl.dispose();
//     super.dispose();
//   }

//   void applyFilter() {
//     String q = searchCtrl.text.toLowerCase();
//     List result = List.from(services);

//     if (activeFilter == 'active') {
//       result = result.where((s) => s['is_active'] == true).toList();
//     } else if (activeFilter == 'inactive') {
//       result = result.where((s) => s['is_active'] == false).toList();
//     }

//     if (q.isNotEmpty) {
//       result = result.where((s) {
//         return (s['name'] ?? '').toString().toLowerCase().contains(q) ||
//             (s['category'] ?? '').toString().toLowerCase().contains(q) ||
//             (s['unit'] ?? '').toString().toLowerCase().contains(q);
//       }).toList();
//     }

//     setState(() => filteredServices = result);
//   }

//   Future<void> loadMarinas() async {
//     setState(() => loadingMarinas = true);
//     try {
//       final dio = await MyDio().getDio();
//       final res = await dio.get('/marinas');
//       List list = res.data['marinas'] ?? [];
//       setState(() {
//         marinas = list;
//         if (list.isNotEmpty) {
//           selectedMarina = list[0];
//           loadServices(list[0]['id']);
//         }
//       });
//     } on DioException catch (e) {
//       dioErrorManager(e);
//     } finally {
//       setState(() => loadingMarinas = false);
//     }
//   }

//   Future<void> loadServices(String marinaId) async {
//     setState(() => loadingServices = true);
//     try {
//       final dio = await MyDio().getDio();
//       final res = await dio.get('/services/marina/$marinaId');
//       setState(() {
//         services = res.data['services'] ?? [];
//         applyFilter();
//       });
//     } on DioException catch (e) {
//       dioErrorManager(e);
//     } finally {
//       setState(() => loadingServices = false);
//     }
//   }

//   Future<void> toggleService(Map service) async {
//     bool isActive = service['is_active'] ?? true;
//     try {
//       final dio = await MyDio().getDio();
//       if (isActive) {
//         await dio.delete('/services/${service['id']}');
//       } else {
//         await dio.patch('/services/${service['id']}/activate');
//       }
//       if (selectedMarina != null) loadServices(selectedMarina!['id']);
//       showSnack(isActive ? 'Service deactivated' : 'Service activated');
//     } on DioException catch (e) {
//       dioErrorManager(e);
//     }
//   }

//   void showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg, style: TextStyle(color: textPrimary)),
//         backgroundColor: navyCard,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   void confirmToggle(Map service) {
//     bool isActive = service['is_active'] ?? true;
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: navyCard,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text(
//           isActive ? 'Deactivate service?' : 'Activate service?',
//           style: TextStyle(
//             color: textPrimary,
//             fontSize: 16,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         content: Text(
//           isActive
//               ? '${service['name']} will be hidden from users.'
//               : '${service['name']} will be visible to users again.',
//           style: TextStyle(color: textSecondary, fontSize: 13),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: Text('Cancel', style: TextStyle(color: textSecondary)),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               toggleService(service);
//             },
//             child: Text(
//               isActive ? 'Deactivate' : 'Activate',
//               style: TextStyle(
//                 color: isActive ? danger : accentGreen,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void openServiceForm({Map? service}) {
//     bool isEdit = service != null;
//     TextEditingController nameCtrl = TextEditingController(
//       text: service?['name'] ?? '',
//     );
//     TextEditingController categoryCtrl = TextEditingController(
//       text: service?['category'] ?? '',
//     );
//     TextEditingController priceCtrl = TextEditingController(
//       text: '${service?['price_per_unit'] ?? ''}',
//     );
//     TextEditingController unitCtrl = TextEditingController(
//       text: service?['unit'] ?? '',
//     );
//     TextEditingController descCtrl = TextEditingController(
//       text: service?['description'] ?? '',
//     );
//     TextEditingController etaCtrl = TextEditingController(
//       text: '${service?['estimated_minutes'] ?? ''}',
//     );

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => Padding(
//         padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
//         child: Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: navyCard,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             border: Border(top: BorderSide(color: divider, width: 0.8)),
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Center(
//                   child: Container(
//                     width: 36,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: divider,
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   isEdit ? 'Edit Service' : 'Add Service',
//                   style: TextStyle(
//                     color: textPrimary,
//                     fontSize: 17,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   'Marina: ${selectedMarina?['name'] ?? ''}',
//                   style: TextStyle(color: textSecondary, fontSize: 12),
//                 ),
//                 SizedBox(height: 16),
//                 buildField(nameCtrl, 'Service name', Icons.build_outlined),
//                 SizedBox(height: 10),
//                 if (!isEdit) ...[
//                   buildField(
//                     categoryCtrl,
//                     'Category (e.g. fuel, cleaning)',
//                     Icons.category_outlined,
//                   ),
//                   SizedBox(height: 10),
//                 ],
//                 Row(
//                   children: [
//                     Expanded(
//                       child: buildField(
//                         priceCtrl,
//                         'Price per unit',
//                         Icons.payments_outlined,
//                         keyboardType: TextInputType.numberWithOptions(
//                           decimal: true,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(
//                       child: buildField(
//                         unitCtrl,
//                         'Unit (e.g. liter)',
//                         Icons.scale_outlined,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 10),
//                 buildField(
//                   descCtrl,
//                   'Description (optional)',
//                   Icons.notes_outlined,
//                 ),
//                 SizedBox(height: 10),
//                 buildField(
//                   etaCtrl,
//                   'Est. minutes (optional)',
//                   Icons.timer_outlined,
//                   keyboardType: TextInputType.number,
//                 ),
//                 SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       try {
//                         final dio = await MyDio().getDio();
//                         if (isEdit) {
//                           await dio.put(
//                             '/services/${service!['id']}',
//                             data: {
//                               'name': nameCtrl.text,
//                               'price_per_unit':
//                                   double.tryParse(priceCtrl.text) ?? 0,
//                               'unit': unitCtrl.text,
//                               'description': descCtrl.text,
//                               'estimated_minutes': int.tryParse(etaCtrl.text),
//                             },
//                           );
//                         } else {
//                           await dio.post(
//                             '/services/marina/${selectedMarina!['id']}',
//                             data: {
//                               'services': [
//                                 {
//                                   'name': nameCtrl.text,
//                                   'category': categoryCtrl.text,
//                                   'price_per_unit':
//                                       double.tryParse(priceCtrl.text) ?? 0,
//                                   'unit': unitCtrl.text,
//                                   'description': descCtrl.text,
//                                   'estimated_minutes': int.tryParse(
//                                     etaCtrl.text,
//                                   ),
//                                 },
//                               ],
//                             },
//                           );
//                         }
//                         Navigator.pop(ctx);
//                         if (selectedMarina != null)
//                           loadServices(selectedMarina!['id']);
//                         showSnack(isEdit ? 'Service updated' : 'Service added');
//                       } on DioException catch (e) {
//                         dioErrorManager(e);
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: gold,
//                       foregroundColor: navy,
//                       padding: EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: Text(
//                       isEdit ? 'Update Service' : 'Add Service',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w700,
//                         fontSize: 15,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 8),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildField(
//     TextEditingController ctrl,
//     String hint,
//     IconData icon, {
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: fieldColor,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: divider, width: 0.8),
//       ),
//       child: TextField(
//         controller: ctrl,
//         keyboardType: keyboardType,
//         style: TextStyle(color: textPrimary, fontSize: 14),
//         decoration: InputDecoration(
//           hintText: hint,
//           hintStyle: TextStyle(color: textSecondary, fontSize: 13),
//           prefixIcon: Icon(icon, color: textSecondary, size: 18),
//           border: InputBorder.none,
//           contentPadding: EdgeInsets.symmetric(vertical: 14),
//           isDense: true,
//         ),
//       ),
//     );
//   }

//   Widget buildServiceCard(Map s) {
//     bool isActive = s['is_active'] ?? true;
//     return Container(
//       margin: EdgeInsets.only(bottom: 10),
//       padding: EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: navyCard,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isActive ? divider : danger.withOpacity(0.25),
//           width: 0.8,
//         ),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: isActive
//                   ? gold.withOpacity(0.1)
//                   : textSecondary.withOpacity(0.08),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(
//               Icons.build_outlined,
//               color: isActive ? gold : textSecondary,
//               size: 20,
//             ),
//           ),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         s['name'] ?? '',
//                         style: TextStyle(
//                           color: isActive ? textPrimary : textSecondary,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           decoration: isActive
//                               ? null
//                               : TextDecoration.lineThrough,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     Container(
//                       padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: (isActive ? accentGreen : danger).withOpacity(
//                           0.1,
//                         ),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         isActive ? 'Active' : 'Inactive',
//                         style: TextStyle(
//                           color: isActive ? accentGreen : danger,
//                           fontSize: 9,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 3),
//                 Text(
//                   s['category'] ?? '',
//                   style: TextStyle(color: textSecondary, fontSize: 12),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 SizedBox(height: 3),
//                 Text(
//                   '${s['price_per_unit']} NOK / ${s['unit'] ?? 'unit'}${s['estimated_minutes'] != null ? ' · ~${s['estimated_minutes']} min' : ''}',
//                   style: TextStyle(
//                     color: isActive ? gold : textSecondary,
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(width: 8),
//           Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               GestureDetector(
//                 onTap: () => openServiceForm(service: s),
//                 child: Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: accentBlue.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(Icons.edit_outlined, color: accentBlue, size: 16),
//                 ),
//               ),
//               SizedBox(height: 6),
//               GestureDetector(
//                 onTap: () => confirmToggle(s),
//                 child: Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: (isActive ? danger : accentGreen).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     isActive
//                         ? Icons.pause_circle_outline
//                         : Icons.play_circle_outline,
//                     color: isActive ? danger : accentGreen,
//                     size: 16,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     int activeCount = services.where((s) => s['is_active'] == true).length;
//     int inactiveCount = services.where((s) => s['is_active'] == false).length;

//     return Scaffold(
//       backgroundColor: navy,
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Padding(
//               padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
//               child: Row(
//                 children: [
//                   Text(
//                     'Services',
//                     style: TextStyle(
//                       color: textPrimary,
//                       fontSize: 22,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   Spacer(),
//                   if (selectedMarina != null)
//                     GestureDetector(
//                       onTap: () => openServiceForm(),
//                       child: Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                         decoration: BoxDecoration(
//                           color: gold,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(Icons.add, color: navy, size: 16),
//                             SizedBox(width: 4),
//                             Text(
//                               'Add',
//                               style: TextStyle(
//                                 color: navy,
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 13,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 12),

//             // Marina picker
//             loadingMarinas
//                 ? Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 16),
//                     child: LinearProgressIndicator(
//                       color: gold,
//                       backgroundColor: navyCard,
//                     ),
//                   )
//                 : SizedBox(
//                     height: 36,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       padding: EdgeInsets.symmetric(horizontal: 16),
//                       itemCount: marinas.length,
//                       itemBuilder: (context, i) {
//                         Map m = marinas[i];
//                         bool isSelected = selectedMarina?['id'] == m['id'];
//                         return GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               selectedMarina = m;
//                               services = [];
//                               filteredServices = [];
//                             });
//                             loadServices(m['id']);
//                           },
//                           child: Container(
//                             margin: EdgeInsets.only(right: 8),
//                             padding: EdgeInsets.symmetric(
//                               horizontal: 14,
//                               vertical: 7,
//                             ),
//                             decoration: BoxDecoration(
//                               color: isSelected ? gold : navyCard,
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(
//                                 color: isSelected ? gold : divider,
//                                 width: 0.8,
//                               ),
//                             ),
//                             child: Text(
//                               m['name'] ?? '',
//                               style: TextStyle(
//                                 color: isSelected ? navy : textSecondary,
//                                 fontSize: 12,
//                                 fontWeight: isSelected
//                                     ? FontWeight.w700
//                                     : FontWeight.w400,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),

//             SizedBox(height: 10),

//             // Search bar
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: navyCard,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: divider, width: 0.8),
//                 ),
//                 child: TextField(
//                   controller: searchCtrl,
//                   style: TextStyle(color: textPrimary, fontSize: 14),
//                   decoration: InputDecoration(
//                     hintText: 'Search by name, category, unit...',
//                     hintStyle: TextStyle(color: textSecondary, fontSize: 13),
//                     prefixIcon: Icon(
//                       Icons.search,
//                       color: textSecondary,
//                       size: 18,
//                     ),
//                     suffixIcon: searchCtrl.text.isNotEmpty
//                         ? GestureDetector(
//                             onTap: () {
//                               searchCtrl.clear();
//                               applyFilter();
//                             },
//                             child: Icon(
//                               Icons.close,
//                               color: textSecondary,
//                               size: 16,
//                             ),
//                           )
//                         : null,
//                     border: InputBorder.none,
//                     contentPadding: EdgeInsets.symmetric(vertical: 13),
//                     isDense: true,
//                   ),
//                 ),
//               ),
//             ),

//             SizedBox(height: 10),

//             // Active / Inactive filter chips
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   buildFilterChip('all', 'All (${services.length})'),
//                   SizedBox(width: 8),
//                   buildFilterChip(
//                     'active',
//                     'Active ($activeCount)',
//                     color: accentGreen,
//                   ),
//                   SizedBox(width: 8),
//                   buildFilterChip(
//                     'inactive',
//                     'Inactive ($inactiveCount)',
//                     color: danger,
//                   ),
//                 ],
//               ),
//             ),

//             SizedBox(height: 10),

//             // Results count
//             if (!loadingServices && services.isNotEmpty)
//               Padding(
//                 padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
//                 child: Text(
//                   '${filteredServices.length} service${filteredServices.length == 1 ? '' : 's'}',
//                   style: TextStyle(color: textSecondary, fontSize: 12),
//                 ),
//               ),

//             // List
//             Expanded(
//               child: RefreshIndicator(
//                 color: gold,
//                 backgroundColor: navyCard,
//                 onRefresh: () async {
//                   if (selectedMarina != null)
//                     await loadServices(selectedMarina!['id']);
//                 },
//                 child: loadingServices
//                     ? Center(child: CircularProgressIndicator(color: gold))
//                     : filteredServices.isEmpty
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.build_circle_outlined,
//                               color: textSecondary,
//                               size: 40,
//                             ),
//                             SizedBox(height: 12),
//                             Text(
//                               services.isEmpty
//                                   ? 'No services for this marina'
//                                   : 'No results found',
//                               style: TextStyle(
//                                 color: textSecondary,
//                                 fontSize: 14,
//                               ),
//                             ),
//                             if (searchCtrl.text.isNotEmpty ||
//                                 activeFilter != 'all') ...[
//                               SizedBox(height: 8),
//                               GestureDetector(
//                                 onTap: () {
//                                   searchCtrl.clear();
//                                   setState(() => activeFilter = 'all');
//                                   applyFilter();
//                                 },
//                                 child: Text(
//                                   'Clear filters',
//                                   style: TextStyle(color: gold, fontSize: 13),
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       )
//                     : ListView.builder(
//                         padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
//                         itemCount: filteredServices.length,
//                         itemBuilder: (context, i) =>
//                             buildServiceCard(filteredServices[i]),
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildFilterChip(String key, String label, {Color? color}) {
//     bool isActive = activeFilter == key;
//     Color chipColor = color ?? gold;
//     return GestureDetector(
//       onTap: () {
//         setState(() => activeFilter = key);
//         applyFilter();
//       },
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: isActive ? chipColor.withOpacity(0.15) : navyCard,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isActive ? chipColor.withOpacity(0.5) : divider,
//             width: 0.8,
//           ),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: isActive ? chipColor : textSecondary,
//             fontSize: 12,
//             fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/utils/colors.dart';

class AdminServicesPage extends StatefulWidget {
  AdminServicesPage({super.key});

  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends State<AdminServicesPage> {
  List marinas = [];
  List services = [];
  List filteredServices = [];
  bool loadingMarinas = true;
  bool loadingServices = false;
  Map? selectedMarina;
  String activeFilter = 'all'; // all, active, inactive
  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMarinas();
    searchCtrl.addListener(applyFilter);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void applyFilter() {
    String q = searchCtrl.text.toLowerCase();
    List result = List.from(services);

    if (activeFilter == 'active') {
      result = result.where((s) => s['is_active'] == true).toList();
    } else if (activeFilter == 'inactive') {
      result = result.where((s) => s['is_active'] == false).toList();
    }

    if (q.isNotEmpty) {
      result = result.where((s) {
        return (s['name'] ?? '').toString().toLowerCase().contains(q) ||
            (s['category'] ?? '').toString().toLowerCase().contains(q) ||
            (s['unit'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }

    setState(() => filteredServices = result);
  }

  Future<void> loadMarinas() async {
    setState(() => loadingMarinas = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/marinas');
      List list = res.data['marinas'] ?? [];
      setState(() {
        marinas = list;
        if (list.isNotEmpty) {
          selectedMarina = list[0];
          loadServices(list[0]['id']);
        }
      });
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loadingMarinas = false);
    }
  }

  Future<void> loadServices(String marinaId) async {
    setState(() => loadingServices = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/services/marina/$marinaId');
      setState(() {
        services = res.data['services'] ?? [];
        applyFilter();
      });
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loadingServices = false);
    }
  }

  Future<void> toggleService(Map service) async {
    bool isActive = service['is_active'] ?? true;
    try {
      final dio = await MyDio().getDio();
      if (isActive) {
        await dio.delete('/services/${service['id']}');
      } else {
        await dio.patch('/services/${service['id']}/activate');
      }
      if (selectedMarina != null) loadServices(selectedMarina!['id']);
      showSnack(isActive ? 'Service deactivated' : 'Service activated');
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

  void confirmToggle(Map service) {
    bool isActive = service['is_active'] ?? true;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isActive ? 'Deactivate service?' : 'Activate service?',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          isActive
              ? '${service['name']} will be hidden from users.'
              : '${service['name']} will be visible to users again.',
          style: TextStyle(color: textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              toggleService(service);
            },
            child: Text(
              isActive ? 'Deactivate' : 'Activate',
              style: TextStyle(
                color: isActive ? danger : accentGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openServiceForm({Map? service}) {
    bool isEdit = service != null;
    TextEditingController nameCtrl = TextEditingController(
      text: service?['name'] ?? '',
    );
    TextEditingController categoryCtrl = TextEditingController(
      text: service?['category'] ?? '',
    );
    TextEditingController priceCtrl = TextEditingController(
      text: '${service?['price_per_unit'] ?? ''}',
    );
    TextEditingController unitCtrl = TextEditingController(
      text: service?['unit'] ?? '',
    );
    TextEditingController descCtrl = TextEditingController(
      text: service?['description'] ?? '',
    );
    TextEditingController etaCtrl = TextEditingController(
      text: '${service?['estimated_minutes'] ?? ''}',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: navyCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(top: BorderSide(color: divider, width: 0.8)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  isEdit ? 'Edit Service' : 'Add Service',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Marina: ${selectedMarina?['name'] ?? ''}',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                SizedBox(height: 16),
                buildField(nameCtrl, 'Service name', Icons.build_outlined),
                SizedBox(height: 10),
                if (!isEdit) ...[
                  buildField(
                    categoryCtrl,
                    'Category (e.g. fuel, cleaning)',
                    Icons.category_outlined,
                  ),
                  SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: buildField(
                        priceCtrl,
                        'Price per unit',
                        Icons.payments_outlined,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: buildField(
                        unitCtrl,
                        'Unit (e.g. liter)',
                        Icons.scale_outlined,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                buildField(
                  descCtrl,
                  'Description (optional)',
                  Icons.notes_outlined,
                ),
                SizedBox(height: 10),
                buildField(
                  etaCtrl,
                  'Est. minutes (optional)',
                  Icons.timer_outlined,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final dio = await MyDio().getDio();
                        if (isEdit) {
                          await dio.put(
                            '/services/${service!['id']}',
                            data: {
                              'name': nameCtrl.text,
                              'price_per_unit':
                                  double.tryParse(priceCtrl.text) ?? 0,
                              'unit': unitCtrl.text,
                              'description': descCtrl.text,
                              'estimated_minutes': int.tryParse(etaCtrl.text),
                            },
                          );
                        } else {
                          await dio.post(
                            '/services/marina/${selectedMarina!['id']}',
                            data: {
                              'services': [
                                {
                                  'name': nameCtrl.text,
                                  'category': categoryCtrl.text,
                                  'price_per_unit':
                                      double.tryParse(priceCtrl.text) ?? 0,
                                  'unit': unitCtrl.text,
                                  'description': descCtrl.text,
                                  'estimated_minutes': int.tryParse(
                                    etaCtrl.text,
                                  ),
                                },
                              ],
                            },
                          );
                        }
                        Navigator.pop(ctx);
                        if (selectedMarina != null)
                          loadServices(selectedMarina!['id']);
                        showSnack(isEdit ? 'Service updated' : 'Service added');
                      } on DioException catch (e) {
                        dioErrorManager(e);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: navy,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEdit ? 'Update Service' : 'Add Service',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider, width: 0.8),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: TextStyle(color: textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: textSecondary, size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
          isDense: true,
        ),
      ),
    );
  }

  Widget buildServiceCard(Map s) {
    bool isActive = s['is_active'] ?? true;
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? divider : danger.withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isActive
                  ? gold.withOpacity(0.1)
                  : textSecondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.build_outlined,
              color: isActive ? gold : textSecondary,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s['name'] ?? '',
                        style: TextStyle(
                          color: isActive ? textPrimary : textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: isActive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isActive ? accentGreen : danger).withOpacity(
                          0.1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isActive ? accentGreen : danger,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3),
                Text(
                  s['category'] ?? '',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3),
                Text(
                  '${s['price_per_unit']} NOK / ${s['unit'] ?? 'unit'}${s['estimated_minutes'] != null ? ' · ~${s['estimated_minutes']} min' : ''}',
                  style: TextStyle(
                    color: isActive ? gold : textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => openServiceForm(service: s),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_outlined, color: accentBlue, size: 16),
                ),
              ),
              SizedBox(height: 6),
              GestureDetector(
                onTap: () => confirmToggle(s),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isActive ? danger : accentGreen).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: isActive ? danger : accentGreen,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int activeCount = services.where((s) => s['is_active'] == true).length;
    int inactiveCount = services.where((s) => s['is_active'] == false).length;

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Services',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  if (selectedMarina != null)
                    GestureDetector(
                      onTap: () => openServiceForm(),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: gold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add, color: navy, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Marina picker
            loadingMarinas
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: LinearProgressIndicator(
                      color: gold,
                      backgroundColor: navyCard,
                    ),
                  )
                : SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: marinas.length,
                      itemBuilder: (context, i) {
                        Map m = marinas[i];
                        bool isSelected = selectedMarina?['id'] == m['id'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedMarina = m;
                              services = [];
                              filteredServices = [];
                            });
                            loadServices(m['id']);
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 8),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? gold : navyCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? gold : divider,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              m['name'] ?? '',
                              style: TextStyle(
                                color: isSelected ? navy : textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected
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

            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
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
                    hintText: 'Search by name, category, unit...',
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
                              applyFilter();
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

            SizedBox(height: 10),

            // Active / Inactive filter chips
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  buildFilterChip('all', 'All (${services.length})'),
                  SizedBox(width: 8),
                  buildFilterChip(
                    'active',
                    'Active ($activeCount)',
                    color: accentGreen,
                  ),
                  SizedBox(width: 8),
                  buildFilterChip(
                    'inactive',
                    'Inactive ($inactiveCount)',
                    color: danger,
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),

            // Results count
            if (!loadingServices && services.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  '${filteredServices.length} service${filteredServices.length == 1 ? '' : 's'}',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ),

            // List
            Expanded(
              child: RefreshIndicator(
                color: gold,
                backgroundColor: navyCard,
                onRefresh: () async {
                  if (selectedMarina != null)
                    await loadServices(selectedMarina!['id']);
                },
                child: loadingServices
                    ? Center(child: CircularProgressIndicator(color: gold))
                    : filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.build_circle_outlined,
                              color: textSecondary,
                              size: 40,
                            ),
                            SizedBox(height: 12),
                            Text(
                              services.isEmpty
                                  ? 'No services for this marina'
                                  : 'No results found',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            if (searchCtrl.text.isNotEmpty ||
                                activeFilter != 'all') ...[
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  searchCtrl.clear();
                                  setState(() => activeFilter = 'all');
                                  applyFilter();
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
                        itemCount: filteredServices.length,
                        itemBuilder: (context, i) =>
                            buildServiceCard(filteredServices[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFilterChip(String key, String label, {Color? color}) {
    bool isActive = activeFilter == key;
    Color chipColor = color ?? gold;
    return GestureDetector(
      onTap: () {
        setState(() => activeFilter = key);
        applyFilter();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? chipColor.withOpacity(0.15) : navyCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? chipColor.withOpacity(0.5) : divider,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? chipColor : textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

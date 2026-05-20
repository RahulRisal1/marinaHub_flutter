import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/utils/colors.dart';

class AdminBerthsPage extends StatefulWidget {
  AdminBerthsPage({super.key});

  @override
  State<AdminBerthsPage> createState() => _AdminBerthsPageState();
}

class _AdminBerthsPageState extends State<AdminBerthsPage> {
  List marinas = [];
  List filteredMarinas = [];
  Map<String, List> berthsByMarina = {};
  Map<String, bool> expanded = {};
  Map<String, bool> loadingBerths = {};
  bool loadingMarinas = true;
  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMarinas();
    searchCtrl.addListener(applySearch);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void applySearch() {
    String q = searchCtrl.text.toLowerCase();
    setState(() {
      filteredMarinas = q.isEmpty
          ? List.from(marinas)
          : marinas.where((m) {
              return (m['name'] ?? '').toString().toLowerCase().contains(q) ||
                  (m['location'] ?? '').toString().toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> loadMarinas() async {
    if (mounted) setState(() => loadingMarinas = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/marinas');
      List list = res.data['marinas'] ?? [];
      if (mounted)
        setState(() {
          marinas = list;
          for (Map m in list) {
            expanded.putIfAbsent(m['id'], () => false);
            berthsByMarina.putIfAbsent(m['id'], () => []);
            loadingBerths.putIfAbsent(m['id'], () => false);
          }
          applySearch();
        });
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      if (mounted) setState(() => loadingMarinas = false);
    }
  }

  Future<void> loadBerthsForMarina(String marinaId) async {
    if (mounted) setState(() => loadingBerths[marinaId] = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get(
        '/berths',
        queryParameters: {'marina_id': marinaId},
      );
      if (mounted)
        setState(() => berthsByMarina[marinaId] = res.data['berths'] ?? []);
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      if (mounted) setState(() => loadingBerths[marinaId] = false);
    }
  }

  void toggleMarina(String marinaId) {
    bool isExpanding = !(expanded[marinaId] ?? false);
    setState(() => expanded[marinaId] = isExpanding);
    if (isExpanding && (berthsByMarina[marinaId] ?? []).isEmpty) {
      loadBerthsForMarina(marinaId);
    }
  }

  Future<void> deleteBerth(String berthId, String marinaId) async {
    try {
      final dio = await MyDio().getDio();
      await dio.delete('/berths/$berthId');
      debugPrint('delete done, now loading berths...');
      await loadBerthsForMarina(marinaId);
      debugPrint('berths loaded, now loading marinas...');
      await loadMarinas();
      debugPrint('marinas loaded');
      if (mounted) showSnack('Berth deleted');
    } on DioException catch (e) {
      debugPrint(
        'DioException: ${e.response?.statusCode} ${e.response?.data} ${e.message}',
      );
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

  void openBerthForm({
    Map? berth,
    required String marinaId,
    required String marinaName,
  }) {
    bool isEdit = berth != null;
    TextEditingController nameCtrl = TextEditingController(
      text: berth?['name'] ?? '',
    );
    TextEditingController lengthCtrl = TextEditingController(
      text: '${berth?['length'] ?? ''}',
    );
    TextEditingController widthCtrl = TextEditingController(
      text: '${berth?['width'] ?? ''}',
    );
    TextEditingController depthCtrl = TextEditingController(
      text: '${berth?['depth'] ?? ''}',
    );
    TextEditingController priceHourCtrl = TextEditingController(
      text: '${berth?['price_per_hour'] ?? ''}',
    );
    TextEditingController priceNightCtrl = TextEditingController(
      text: '${berth?['price_per_night'] ?? ''}',
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
                  isEdit ? 'Edit Berth' : 'Add Berth',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  marinaName,
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
                SizedBox(height: 16),
                buildField(nameCtrl, 'Berth name (e.g. A-3)', Icons.anchor),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: buildField(
                        lengthCtrl,
                        'Length (m)',
                        Icons.straighten,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: buildField(
                        widthCtrl,
                        'Width (m)',
                        Icons.straighten,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: buildField(
                        depthCtrl,
                        'Depth (m)',
                        Icons.water,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: buildField(
                        priceHourCtrl,
                        'NOK/hr',
                        Icons.payments_outlined,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: buildField(
                        priceNightCtrl,
                        'NOK/night',
                        Icons.nights_stay_outlined,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final dio = await MyDio().getDio();
                        Map<String, dynamic> data = {
                          'name': nameCtrl.text,
                          'length': double.tryParse(lengthCtrl.text),
                          'width': double.tryParse(widthCtrl.text),
                          'depth': double.tryParse(depthCtrl.text),
                          'price_per_hour': double.tryParse(priceHourCtrl.text),
                          'price_per_night': double.tryParse(
                            priceNightCtrl.text,
                          ),
                        };
                        if (isEdit) {
                          await dio.put('/berths/${berth!['id']}', data: data);
                        } else {
                          data['marina_id'] = marinaId;
                          await dio.post('/berths', data: data);
                        }
                        Navigator.pop(ctx);
                        await loadBerthsForMarina(marinaId);
                        await loadMarinas();
                        showSnack(isEdit ? 'Berth updated' : 'Berth created');
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
                      isEdit ? 'Update Berth' : 'Create Berth',
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
        style: TextStyle(color: textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textSecondary, fontSize: 12),
          prefixIcon: Icon(icon, color: textSecondary, size: 16),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13),
          isDense: true,
        ),
      ),
    );
  }

  void confirmDelete(Map berth, String marinaId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete berth?',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '${berth['name']} will be permanently deleted.',
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
              deleteBerth(berth['id'], marinaId);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBerthCard(Map berth, String marinaId, String marinaName) {
    bool available = berth['is_available'] ?? true;
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: divider, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (available ? accentGreen : danger).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_boat,
              color: available ? accentGreen : danger,
              size: 17,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  berth['name'] ?? '',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '${berth['length']}m × ${berth['width']}m · ${berth['depth']}m deep',
                  style: TextStyle(color: textSecondary, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '${berth['price_per_night']} NOK/night · ${berth['price_per_hour']} NOK/hr',
                  style: TextStyle(color: gold, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (available ? accentGreen : danger).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  available ? 'Free' : 'Booked',
                  style: TextStyle(
                    color: available ? accentGreen : danger,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => openBerthForm(
                      berth: berth,
                      marinaId: marinaId,
                      marinaName: marinaName,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: accentBlue,
                        size: 13,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => confirmDelete(berth, marinaId),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: danger,
                        size: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
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
              padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text(
                'Berths',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                    hintText: 'Search marinas...',
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
                              applySearch();
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

            Expanded(
              child: RefreshIndicator(
                color: gold,
                backgroundColor: navyCard,
                onRefresh: loadMarinas,
                child: loadingMarinas
                    ? Center(child: CircularProgressIndicator(color: gold))
                    : filteredMarinas.isEmpty
                    ? Center(
                        child: Text(
                          marinas.isEmpty
                              ? 'No marinas found'
                              : 'No results for "${searchCtrl.text}"',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: filteredMarinas.length,
                        itemBuilder: (context, i) {
                          Map marina = filteredMarinas[i];
                          String marinaId = marina['id'];
                          String marinaName = marina['name'] ?? '';
                          bool isExpanded = expanded[marinaId] ?? false;
                          bool isLoadingBerths =
                              loadingBerths[marinaId] ?? false;
                          List marinaBerths = berthsByMarina[marinaId] ?? [];

                          return Container(
                            margin: EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: navyCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isExpanded
                                    ? gold.withOpacity(0.3)
                                    : divider,
                                width: 0.8,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Marina header
                                GestureDetector(
                                  onTap: () => toggleMarina(marinaId),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: accentBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            color: accentBlue,
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
                                                marinaName,
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
                                                marina['location'] ?? '',
                                                style: TextStyle(
                                                  color: textSecondary,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: gold.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '${marina['totalBerths'] ?? 0} berths',
                                            style: TextStyle(
                                              color: gold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.5 : 0,
                                          duration: Duration(milliseconds: 200),
                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            color: textSecondary,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Expanded section
                                AnimatedCrossFade(
                                  duration: Duration(milliseconds: 250),
                                  crossFadeState: isExpanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  firstChild: SizedBox.shrink(),
                                  secondChild: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Divider(
                                        height: 0,
                                        thickness: 0.5,
                                        color: divider,
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            // Add berth button
                                            GestureDetector(
                                              onTap: () => openBerthForm(
                                                marinaId: marinaId,
                                                marinaName: marinaName,
                                              ),
                                              child: Container(
                                                width: double.infinity,
                                                margin: EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: gold.withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: gold.withOpacity(
                                                      0.25,
                                                    ),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add,
                                                      color: gold,
                                                      size: 15,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        'Add berth to $marinaName',
                                                        style: TextStyle(
                                                          color: gold,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            if (isLoadingBerths)
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: gold,
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              )
                                            else if (marinaBerths.isEmpty)
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    'No berths yet',
                                                    style: TextStyle(
                                                      color: textSecondary,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            else
                                              ...marinaBerths
                                                  .map(
                                                    (berth) => buildBerthCard(
                                                      berth,
                                                      marinaId,
                                                      marinaName,
                                                    ),
                                                  )
                                                  .toList(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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

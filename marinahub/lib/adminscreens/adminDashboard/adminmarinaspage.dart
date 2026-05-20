import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/utils/colors.dart';

class AdminMarinasPage extends StatefulWidget {
  AdminMarinasPage({super.key});

  @override
  State<AdminMarinasPage> createState() => _AdminMarinasPageState();
}

class _AdminMarinasPageState extends State<AdminMarinasPage> {
  List marinas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMarinas();
  }

  Future<void> loadMarinas() async {
    setState(() => loading = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/marinas');
      setState(() => marinas = res.data['marinas'] ?? []);
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> deleteMarina(String id) async {
    try {
      final dio = await MyDio().getDio();
      await dio.delete('/marinas/$id');
      loadMarinas();
      showSnack('Marina deleted');
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

  void openMarinaForm({Map? marina}) {
    TextEditingController nameCtrl = TextEditingController(
      text: marina?['name'] ?? '',
    );
    TextEditingController locationCtrl = TextEditingController(
      text: marina?['location'] ?? '',
    );
    TextEditingController latCtrl = TextEditingController(
      text: '${marina?['latitude'] ?? ''}',
    );
    TextEditingController lngCtrl = TextEditingController(
      text: '${marina?['longitude'] ?? ''}',
    );
    TextEditingController descCtrl = TextEditingController(
      text: marina?['description'] ?? '',
    );
    bool isEdit = marina != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
                  isEdit ? 'Edit Marina' : 'Add Marina',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16),
                buildField(nameCtrl, 'Marina name', Icons.location_on_outlined),
                SizedBox(height: 10),
                buildField(locationCtrl, 'Location', Icons.place_outlined),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: buildField(
                        latCtrl,
                        'Latitude',
                        Icons.my_location,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: buildField(
                        lngCtrl,
                        'Longitude',
                        Icons.my_location,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final dio = await MyDio().getDio();
                        Map<String, dynamic> data = {
                          'name': nameCtrl.text,
                          'location': locationCtrl.text,
                          'latitude': double.tryParse(latCtrl.text),
                          'longitude': double.tryParse(lngCtrl.text),
                          'description': descCtrl.text,
                        };
                        if (isEdit) {
                          await dio.put(
                            '/marinas/${marina!['id']}',
                            data: data,
                          );
                        } else {
                          await dio.post('/marinas', data: data);
                        }
                        Navigator.pop(ctx);
                        loadMarinas();
                        showSnack(isEdit ? 'Marina updated' : 'Marina created');
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
                      isEdit ? 'Update Marina' : 'Create Marina',
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
          hintStyle: TextStyle(color: textSecondary, fontSize: 14),
          prefixIcon: Icon(icon, color: textSecondary, size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  void confirmDelete(Map marina) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete marina?',
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '${marina['name']} will be permanently deleted.',
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
              deleteMarina(marina['id']);
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
              child: Row(
                children: [
                  Text(
                    'Marinas',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () => openMarinaForm(),
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
            Expanded(
              child: RefreshIndicator(
                color: gold,
                backgroundColor: navyCard,
                onRefresh: loadMarinas,
                child: loading
                    ? Center(child: CircularProgressIndicator(color: gold))
                    : marinas.isEmpty
                    ? Center(
                        child: Text(
                          'No marinas found',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: marinas.length,
                        itemBuilder: (context, i) {
                          Map marina = marinas[i];
                          return Container(
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
                                    color: accentBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: accentBlue,
                                    size: 22,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        marina['name'] ?? '',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.anchor,
                                            color: gold,
                                            size: 12,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '${marina['totalBerths'] ?? 0} berths',
                                            style: TextStyle(
                                              color: gold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () =>
                                          openMarinaForm(marina: marina),
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: accentBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          color: accentBlue,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => confirmDelete(marina),
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: danger.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: danger,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
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

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:marinahub/dio/myDio.dart';
import 'package:marinahub/dio/dioErrorManager.dart';
import 'package:marinahub/utils/colors.dart';

class AdminUsersPage extends StatefulWidget {
  AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List users = [];
  List filtered = [];
  bool loading = true;
  String activeFilter = 'all';
  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUsers();
    searchCtrl.addListener(applyFilter);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    setState(() => loading = true);
    try {
      final dio = await MyDio().getDio();
      final res = await dio.get('/users/all');
      setState(() {
        users = res.data['users'] ?? [];
        applyFilter();
      });
    } on DioException catch (e) {
      dioErrorManager(e);
    } finally {
      setState(() => loading = false);
    }
  }

  void applyFilter() {
    String query = searchCtrl.text.toLowerCase();
    List base = activeFilter == 'all'
        ? users
        : users.where((u) => u['role'] == activeFilter).toList();
    if (query.isEmpty) {
      setState(() => filtered = List.from(base));
    } else {
      setState(
        () => filtered = base.where((u) {
          return (u['name'] ?? '').toString().toLowerCase().contains(query) ||
              (u['email'] ?? '').toString().toLowerCase().contains(query);
        }).toList(),
      );
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
                'Users',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 12),

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
                    hintText: 'Search by name or email...',
                    hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search,
                      color: textSecondary,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),

            // Role filter
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: ['all', 'boater', 'admin'].map((f) {
                  bool isActive = activeFilter == f;
                  return GestureDetector(
                    onTap: () {
                      setState(() => activeFilter = f);
                      applyFilter();
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
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
                        f == 'all' ? 'All users' : f,
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
                }).toList(),
              ),
            ),
            SizedBox(height: 12),

            Expanded(
              child: RefreshIndicator(
                color: gold,
                backgroundColor: navyCard,
                onRefresh: loadUsers,
                child: loading
                    ? Center(child: CircularProgressIndicator(color: gold))
                    : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          Map u = filtered[i];
                          bool isAdmin = u['role'] == 'admin';
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
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: (isAdmin ? gold : accentBlue)
                                      .withOpacity(0.15),
                                  child: Text(
                                    (u['name'] ?? 'U')
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: isAdmin ? gold : accentBlue,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u['name'] ?? 'Unknown',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        u['email'] ?? '',
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
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isAdmin ? gold : accentBlue)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    u['role'] ?? 'boater',
                                    style: TextStyle(
                                      color: isAdmin ? gold : accentBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
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

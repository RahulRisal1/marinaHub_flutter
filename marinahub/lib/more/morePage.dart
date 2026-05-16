import 'package:flutter/material.dart';
import 'package:marinahub/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinahub/auth/loginScreen.dart';
import 'package:marinahub/dashboardscreen/dashboardscreen.dart';
import 'package:marinahub/provider/userProvider.dart';
import 'package:marinahub/screens/profile/profileScreen.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => MorePageState();
}

class MorePageState extends State<MorePage> {
  final TextEditingController searchController = TextEditingController();
  String query = '';

  String initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void navigate(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> confirmSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    if (token == null || token.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Not logged in',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'You are not currently logged in. Please log in to access your account.',
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: TextStyle(color: textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Text(
                'Go to login',
                style: TextStyle(
                  color: accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign out?',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You will need to log in again to access your bookings.',
          style: TextStyle(color: textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sign out',
              style: TextStyle(color: danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await context.read<UserProvider>().clearUserData();
      await prefs.clear();
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LoginScreen()));
    }
  }

  Widget comingSoon(String title) {
    return Scaffold(
      backgroundColor: Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Color(0xFF0A1628),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFFE8EFF8)),
        title: Text(
          title,
          style: TextStyle(
            color: Color(0xFFE8EFF8),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Color(0xFF0F1F35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF1E2D45), width: 0.5),
              ),
              child: Icon(
                Icons.rocket_launch_outlined,
                color: Color(0xFF4A9EFF),
                size: 32,
              ),
            ),
            SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: Color(0xFFE8EFF8),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon',
              style: TextStyle(color: Color(0xFF6B8BB0), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> buildSections() {
    return [
      {
        'label': 'Navigation',
        'items': [
          {
            'title': 'Profile',
            'description': 'Personal info & vessel details',
            'icon': Icons.person_outline_rounded,
            'iconColor': Color(0xFF4A9EFF),
            'iconBg': Color(0xFF0D2A4A),
            'trailing': null,
            'onTap': () => navigate(profileScreen()),
          },
          {
            'title': 'Boat Map',
            'description': 'Live position & route planner',
            'icon': Icons.map_outlined,
            'iconColor': Color(0xFF1D9E75),
            'iconBg': Color(0xFF0A2A1E),
            'trailing': 'live',
            'onTap': () => navigate(DashboardScreen(initialTab: 1)),
          },
        ],
      },
      {
        'label': 'Fleet & Trips',
        'items': [
          {
            'title': 'My Vessels',
            'description': 'Manage your fleet',
            'icon': Icons.anchor_outlined,
            'iconColor': Color(0xFFEF9F27),
            'iconBg': Color(0xFF1A1A0D),
            'trailing': null,
            'onTap': () => navigate(comingSoon('My Vessels')),
          },
          {
            'title': 'Trip History',
            'description': 'Past voyages & logs',
            'icon': Icons.route_outlined,
            'iconColor': Color(0xFF9F7AEA),
            'iconBg': Color(0xFF1A0A1A),
            'trailing': 'count:3 new',
            'onTap': () => navigate(comingSoon('Trip History')),
          },
          {
            'title': 'Weather',
            'description': 'Marine forecasts',
            'icon': Icons.cloud_outlined,
            'iconColor': Color(0xFF38B2AC),
            'iconBg': Color(0xFF0A1A1A),
            'trailing': null,
            'onTap': () => navigate(comingSoon('Weather')),
          },
        ],
      },
      {
        'label': 'Account',
        'items': [
          {
            'title': 'Settings',
            'description': 'App preferences',
            'icon': Icons.settings_outlined,
            'iconColor': Color(0xFF4A9EFF),
            'iconBg': Color(0xFF0D1A2A),
            'trailing': null,
            'onTap': () => navigate(comingSoon('Settings')),
          },
          {
            'title': 'Help & Support',
            'description': 'FAQs & contact',
            'icon': Icons.help_outline_rounded,
            'iconColor': Color(0xFFE24B4A),
            'iconBg': Color(0xFF1A0D0D),
            'trailing': null,
            'onTap': () => navigate(comingSoon('Help & Support')),
          },
          {
            'title': 'Sign Out',
            'description': 'Log out of your account',
            'icon': Icons.logout_rounded,
            'iconColor': Color(0xFF48BB78),
            'iconBg': Color(0xFF0A1A0A),
            'trailing': null,
            'onTap': () => confirmSignOut(),
          },
        ],
      },
    ];
  }

  Widget buildTrailing(dynamic trailing, double scale) {
    if (trailing == null) {
      return Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF3A5070),
        size: 18 * scale,
      );
    }
    if (trailing == 'live') {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 3 * scale,
        ),
        decoration: BoxDecoration(
          color: Color(0xFF1D9E75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Live',
          style: TextStyle(
            color: Color(0xFFE1F5EE),
            fontSize: 10 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    if (trailing is String && trailing.startsWith('count:')) {
      final label = trailing.replaceFirst('count:', '');
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 3 * scale,
        ),
        decoration: BoxDecoration(
          color: Color(0xFF1A1205),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Color(0xFFBA7517),
            fontSize: 10 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return Icon(
      Icons.chevron_right_rounded,
      color: Color(0xFF3A5070),
      size: 18 * scale,
    );
  }

  List<Map<String, dynamic>> get filteredSections {
    final sections = buildSections();
    if (query.isEmpty) return sections;
    final q = query.toLowerCase();
    return sections
        .map((s) {
          final items = (s['items'] as List<Map<String, dynamic>>)
              .where(
                (i) =>
                    (i['title'] as String).toLowerCase().contains(q) ||
                    (i['description'] as String).toLowerCase().contains(q),
              )
              .toList();
          return {'label': s['label'], 'items': items};
        })
        .where((s) => (s['items'] as List).isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final userData = userProvider.userData;
    final displayName = (userData?['name'] ?? 'User').toString();
    final displayEmail = (userData?['email'] ?? '').toString();
    final displayRole = (userData?['role'] ?? '').toString();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isTablet = screenWidth >= 600;
            final isLargeTablet = screenWidth >= 900;

            final scale = isLargeTablet ? 1.3 : (isTablet ? 1.15 : 1.0);
            final hPad = isLargeTablet ? 48.0 : (isTablet ? 32.0 : 16.0);
            final contentMaxWidth = isTablet ? 720.0 : double.infinity;

            Widget content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 16 * scale, hPad, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'More',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 24 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none_rounded,
                          color: textSecondary,
                          size: 24 * scale,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: 8 * scale,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52 * scale,
                        height: 52 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accentGreen, accentBlue],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initials(displayName.toUpperCase()),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14 * scale),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName.toUpperCase(),
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              displayRole.isNotEmpty
                                  ? '$displayRole · $displayEmail'
                                  : displayEmail,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12 * scale,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => navigate(profileScreen()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondary,
                          side: BorderSide(color: border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14 * scale,
                            vertical: 6 * scale,
                          ),
                          textStyle: TextStyle(fontSize: 12 * scale),
                        ),
                        child: Text('Edit'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 12 * scale),
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(color: textPrimary, fontSize: 14 * scale),
                    decoration: InputDecoration(
                      hintText: 'Search settings…',
                      hintStyle: TextStyle(
                        color: textSecondary,
                        fontSize: 14 * scale,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: textSecondary,
                        size: 20 * scale,
                      ),
                      filled: true,
                      fillColor: surface,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12 * scale,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentBlue, width: 1),
                      ),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                Expanded(
                  child: filteredSections.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                color: textSecondary,
                                size: 40 * scale,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No results for "$query"',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14 * scale,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.only(bottom: 24),
                          children: [
                            ...filteredSections.map((s) {
                              final items =
                                  s['items'] as List<Map<String, dynamic>>;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      hPad,
                                      8 * scale,
                                      hPad,
                                      8 * scale,
                                    ),
                                    child: Text(
                                      (s['label'] as String).toUpperCase(),
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11 * scale,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: hPad,
                                    ),
                                    decoration: BoxDecoration(
                                      color: surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: border,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: List.generate(items.length, (
                                        i,
                                      ) {
                                        final item = items[i];
                                        final isLast = i == items.length - 1;
                                        return Column(
                                          children: [
                                            InkWell(
                                              onTap:
                                                  item['onTap']
                                                      as VoidCallback?,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16 * scale,
                                                  vertical: 13 * scale,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 36 * scale,
                                                      height: 36 * scale,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            item['iconBg']
                                                                as Color,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        item['icon']
                                                            as IconData,
                                                        color:
                                                            item['iconColor']
                                                                as Color,
                                                        size: 18 * scale,
                                                      ),
                                                    ),
                                                    SizedBox(width: 14 * scale),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item['title']
                                                                as String,
                                                            style: TextStyle(
                                                              color:
                                                                  textPrimary,
                                                              fontSize:
                                                                  14 * scale,
                                                            ),
                                                          ),
                                                          SizedBox(height: 2),
                                                          Text(
                                                            item['description']
                                                                as String,
                                                            style: TextStyle(
                                                              color:
                                                                  textSecondary,
                                                              fontSize:
                                                                  11 * scale,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    buildTrailing(
                                                      item['trailing'],
                                                      scale,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (!isLast)
                                              Divider(
                                                height: 0,
                                                thickness: 0.5,
                                                indent: 66 * scale,
                                                color: border,
                                              ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ),
                                  SizedBox(height: 4 * scale),
                                ],
                              );
                            }),
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'v2.4.1 · MarineOS',
                                  style: TextStyle(
                                    color: Color(0xFF3A5070),
                                    fontSize: 11 * scale,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );

            if (isTablet) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: content,
                ),
              );
            }

            return content;
          },
        ),
      ),
    );
  }
}

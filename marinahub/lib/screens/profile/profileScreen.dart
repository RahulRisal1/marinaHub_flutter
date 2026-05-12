import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinahub/auth/loginScreen.dart';
import 'package:marinahub/provider/userProvider.dart';

class profileScreen extends StatefulWidget {
  const profileScreen({super.key});

  @override
  State<profileScreen> createState() => profileScreenState();
}

class profileScreenState extends State<profileScreen> {
  static const Color navy = Color(0xFF0B1A2E);
  static const Color navyCard = Color(0xFF13243B);
  static const Color gold = Color(0xFFD4A857);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8A99B0);
  static const Color danger = Color(0xFFE25C5C);
  static const Color divider = Color(0xFF1E3050);

  static const String avatarAsset = 'assets/images/logo.gif';

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isLoggedIn = userProvider.isLoggedIn;
    final userData = userProvider.userData;

    final displayName = isLoggedIn
        ? (userData?["name"] ?? "User").toString()
        : "Guest user";
    final displayEmail = isLoggedIn
        ? (userData?["email"] ?? "").toString()
        : "Sign in to access all features";

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildAvatar(),
              const SizedBox(height: 14),
              Text(
                displayName,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayEmail,
                style: const TextStyle(color: textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              if (!isLoggedIn) buildSignInBanner(),
              if (!isLoggedIn) const SizedBox(height: 16),
              buildSection([
                buildMenuTile(
                  icon: Icons.person_outline,
                  title: 'Personal information',
                  onTap: () {},
                ),
                buildDivider(),
                buildMenuTile(
                  icon: Icons.credit_card_outlined,
                  title: 'Payment methods',
                  onTap: () {},
                ),
                buildDivider(),
                buildMenuTile(
                  icon: Icons.bookmark_border,
                  title: 'Saved marinas',
                  onTap: () {},
                ),
                buildDivider(),
                buildMenuTile(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 16),
              buildSection([
                buildMenuTile(
                  icon: Icons.help_outline,
                  title: 'Help & support',
                  onTap: () {},
                ),
                buildDivider(),
                buildMenuTile(
                  icon: Icons.shield_outlined,
                  title: 'Terms & privacy',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 24),
              if (isLoggedIn)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: confirmLogout,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: danger, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Log out',
                      style: TextStyle(
                        color: danger,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: gold, width: 2),
          ),
          padding: const EdgeInsets.all(3),
          child: const CircleAvatar(
            backgroundColor: navyCard,
            backgroundImage: AssetImage(avatarAsset),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
              border: Border.all(color: navy, width: 2),
            ),
            child: const Icon(Icons.anchor, size: 14, color: navy),
          ),
        ),
      ],
    );
  }

  Widget buildSignInBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: gold, size: 20),
              SizedBox(width: 8),
              Text(
                'Browsing as guest',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Log in to book berths, save favourites and manage your bookings.',
            style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: navy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Log in or create account',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: textPrimary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDivider() {
    return const Divider(
      color: divider,
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  Future<void> confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log out?',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You will need to log in again to access your bookings.',
          style: TextStyle(color: textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Log out',
              style: TextStyle(color: danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await context.read<UserProvider>().clearUserData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:marinahub/adminscreens/adminsplash.dart';
import 'package:marinahub/auth/loginScreen.dart';
import 'package:marinahub/auth/registerScreen.dart';
import 'package:marinahub/dashboardscreen/dashboardscreen.dart';
import 'package:marinahub/screens/splashScreenHelper.dart';
import 'package:marinahub/provider/userProvider.dart';
import 'package:marinahub/serviceScreen/serviceScreen.dart';
import 'package:provider/provider.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  bool dataLoaded = false;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    await context.read<UserProvider>().getUser();
    if (mounted) {
      setState(() => dataLoaded = true);
    }
  }

  void navigateBasedOnRole(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final role = userProvider.userData?["role"];
    final name = userProvider.userData?["name"] ?? "User";
    final email = userProvider.userData?["email"] ?? "";

    Widget destination;
    switch (role) {
      case "boater":
        destination = DashboardScreen();
        break;
      case "admin":
        destination = DashboardScreen();
        break;
      case "service":
        destination = serviceSplash();
        break;
      default:
        destination = DashboardScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1421),
      body: SplashScreenHelper(
        onComplete: () {
          if (dataLoaded) {
            navigateBasedOnRole(context);
          } else {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) navigateBasedOnRole(context);
            });
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:marinahub/dashboardscreen/dashboardscreen.dart';
import 'package:marinahub/screens/homePage.dart';
import 'package:marinahub/screens/splashScreenHelper.dart';

class Splashscreen extends StatelessWidget {
  const Splashscreen({super.key});

  void navigateToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(seconds: 3),
        pageBuilder: (_, __, ___) => DashboardScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1421),
      body: SplashScreenHelper(onComplete: () => navigateToHome(context)),
    );
  }
}

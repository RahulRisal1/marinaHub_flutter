import 'package:flutter/material.dart';

class adminSplash extends StatefulWidget {
  const adminSplash({super.key});

  @override
  State<adminSplash> createState() => _adminSplashState();
}

class _adminSplashState extends State<adminSplash> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1421),
      body: const Center(
        child: Text(
          'Admin Splash Screen',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class serviceSplash extends StatefulWidget {
  const serviceSplash({super.key});

  @override
  State<serviceSplash> createState() => _serviceSplashState();
}

class _serviceSplashState extends State<serviceSplash> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1421),
      body: const Center(
        child: Text(
          'Service Dashboard Screen',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}

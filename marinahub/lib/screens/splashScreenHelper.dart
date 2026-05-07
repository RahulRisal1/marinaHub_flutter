import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreenHelper extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreenHelper({super.key, required this.onComplete});

  @override
  State<SplashScreenHelper> createState() => _SplashScreenHelperState();
}

class _SplashScreenHelperState extends State<SplashScreenHelper>
    with TickerProviderStateMixin {
  late AnimationController fadeController;
  late AnimationController waveController;

  late Animation<double> fadeAnimation;

  String fullText = 'PREMIUM MARINA BOOKINGS';
  String displayText = '';

  @override
  void initState() {
    super.initState();
    setupAnimations();
    startSequence();
  }

  void setupAnimations() {
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeIn));
  }

  void startSequence() async {
    waveController.repeat();
    await Future.delayed(const Duration(milliseconds: 300));
    fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    startTypewriter();
    await Future.delayed(const Duration(milliseconds: 3000));
    widget.onComplete();
  }

  void startTypewriter() async {
    for (int i = 0; i <= fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 65));
      if (mounted) {
        setState(() => displayText = fullText.substring(0, i));
      }
    }
  }

  @override
  void dispose() {
    fadeController.dispose();
    waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0D1B2A),
                  const Color(0xFF0A1520),
                  const Color(0xFF0D1B2A),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: waveController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(width, height * 0.18),
                painter: WavePainter(waveController.value),
              );
            },
          ),
        ),

        FadeTransition(
          opacity: fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: height * 0.1),
              Center(
                child: Image.asset(
                  'assets/images/anchor.png',
                  width: width * 0.85,
                  height: width * 0.85,
                  fit: BoxFit.contain,
                ),
              ),

              SizedBox(height: height * 0.045),

              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'MARINA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.09,
                          letterSpacing: 8,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      TextSpan(
                        text: 'HUB',
                        style: TextStyle(
                          color: const Color(0xFFC9A84C),
                          fontSize: width * 0.09,
                          letterSpacing: 8,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: height * 0.015),

              Center(
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: const Color(0xFF8A9BB0),
                    fontSize: width * 0.026,
                    letterSpacing: 3.5,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double progress;

  WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFC9A84C).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paint2 = Paint()
      ..color = const Color(0xFFC9A84C).withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.5);
    for (double x = 0; x <= size.width; x += 1) {
      final y =
          size.height * 0.5 +
          sin(x / size.width * 2 * pi + progress * 2 * pi) *
              size.height *
              0.22 +
          sin(x / size.width * 3.5 * pi + progress * 2 * pi * 0.8) *
              size.height *
              0.08;
      path1.lineTo(x, y);
    }
    canvas.drawPath(path1, paint1);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.72);
    for (double x = 0; x <= size.width; x += 1) {
      final y =
          size.height * 0.72 +
          sin(x / size.width * 2 * pi + progress * 2 * pi + 1.2) *
              size.height *
              0.16 +
          sin(x / size.width * 4 * pi + progress * 2 * pi * 0.6) *
              size.height *
              0.06;
      path2.lineTo(x, y);
    }
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

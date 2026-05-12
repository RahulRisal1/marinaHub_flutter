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
  late AnimationController glowController;

  late Animation<double> fadeAnimation;
  late Animation<double> anchorScaleAnimation;
  late Animation<double> glowAnimation;

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
      duration: const Duration(milliseconds: 1400),
    );

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeInOut));

    anchorScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: fadeController, curve: Curves.easeOutBack),
    );

    glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));
  }

  void startSequence() async {
    glowController.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 200));
    fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    startTypewriter();
    await Future.delayed(const Duration(milliseconds: 3500));
    widget.onComplete();
  }

  void startTypewriter() async {
    for (int i = 0; i <= fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      if (mounted) {
        setState(() => displayText = fullText.substring(0, i));
      }
    }
  }

  @override
  void dispose() {
    fadeController.dispose();
    glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      body: Stack(
        children: [
          // Deep ocean radial gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF0D1B2A),
                    Color(0xFF071019),
                    Color(0xFF030710),
                  ],
                ),
              ),
            ),
          ),

          // Floating gold particles
          ...List.generate(20, (index) {
            return _FloatingParticle(
              delay: index * 200,
              screenWidth: width,
              screenHeight: height,
            );
          }),

          // Main content
          FadeTransition(
            opacity: fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Anchor with golden glow
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      anchorScaleAnimation,
                      glowAnimation,
                    ]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: anchorScaleAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFC9A84C,
                                ).withOpacity(0.4 * glowAnimation.value),
                                blurRadius: 60 * glowAnimation.value,
                                spreadRadius: 8,
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xFFC9A84C,
                                ).withOpacity(0.2 * glowAnimation.value),
                                blurRadius: 100,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/anchor.png',
                            width: width * 0.35,
                            height: width * 0.35,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: height * 0.06),

                  // MARINAHUB
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'MARINA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.09,
                            letterSpacing: 7,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                        TextSpan(
                          text: 'HUB',
                          style: TextStyle(
                            color: const Color(0xFFC9A84C),
                            fontSize: width * 0.09,
                            letterSpacing: 7,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: height * 0.022),

                  // Gold separator line
                  Container(
                    width: width * 0.15,
                    height: 0.8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFC9A84C).withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.022),

                  // Tagline
                  Text(
                    displayText,
                    style: TextStyle(
                      color: const Color(0xFF8A9BB0),
                      fontSize: width * 0.028,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingParticle extends StatefulWidget {
  final int delay;
  final double screenWidth;
  final double screenHeight;

  const _FloatingParticle({
    required this.delay,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late double startX;
  late double startY;
  late double size;
  late double duration;

  @override
  void initState() {
    super.initState();
    final random = Random();
    startX = random.nextDouble() * widget.screenWidth;
    startY = widget.screenHeight + random.nextDouble() * 100;
    size = 1.0 + random.nextDouble() * 2.0;
    duration = 8.0 + random.nextDouble() * 6.0;

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (duration * 1000).toInt()),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) controller.repeat();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = controller.value;
        final y = startY - (widget.screenHeight + 200) * progress;
        final opacity = sin(progress * pi) * 0.6;

        return Positioned(
          left: startX,
          top: y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC9A84C).withOpacity(opacity),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC9A84C).withOpacity(opacity * 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:marinahub/adminscreens/adminDashboard/adminDashboard.dart';
import 'package:marinahub/utils/colors.dart';

class AdminSplash extends StatefulWidget {
  AdminSplash({super.key, this.platformManager = false});

  final bool platformManager;

  @override
  State<AdminSplash> createState() => _AdminSplashState();
}

class _AdminSplashState extends State<AdminSplash>
    with TickerProviderStateMixin {
  late AnimationController logoController;
  late AnimationController contentController;
  late AnimationController barController;
  late AnimationController pulseController;

  late Animation<double> logoScale;
  late Animation<double> logoFade;
  late Animation<double> contentFade;
  late Animation<Offset> contentSlide;
  late Animation<double> barProgress;
  late Animation<double> pulse;

  @override
  void initState() {
    super.initState();

    logoController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    contentController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    );
    barController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800),
    );
    pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    logoScale = CurvedAnimation(
      parent: logoController,
      curve: Curves.easeOutBack,
    );
    logoFade = CurvedAnimation(parent: logoController, curve: Curves.easeIn);
    contentFade = CurvedAnimation(
      parent: contentController,
      curve: Curves.easeIn,
    );
    contentSlide = Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: contentController, curve: Curves.easeOut),
        );
    barProgress = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: barController, curve: Curves.easeInOut));
    pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );

    startSequence();
  }

  Future<void> startSequence() async {
    await Future.delayed(Duration(milliseconds: 300));
    logoController.forward();
    await Future.delayed(Duration(milliseconds: 600));
    contentController.forward();
    barController.forward();
    await Future.delayed(Duration(milliseconds: 2200));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, anim, sec) => AdminDashboard(),
          transitionsBuilder: (ctx, anim, sec, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    logoController.dispose();
    contentController.dispose();
    barController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  Widget buildStatPill(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: navyCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: divider, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(icon, color: gold, size: 16),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: textSecondary,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDotGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double spacing = 32.0;
        int cols = (constraints.maxWidth / spacing).ceil();
        int rows = (constraints.maxHeight / spacing).ceil();
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: List.generate(cols * rows, (i) {
              int col = i % cols;
              int row = i ~/ cols;
              return Positioned(
                left: col * spacing,
                top: row * spacing,
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: divider.withOpacity(0.3),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Stack(
        children: [
          buildDotGrid(),

          Center(
            child: ScaleTransition(
              scale: pulse,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      gold.withOpacity(0.08),
                      gold.withOpacity(0.03),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Spacer(flex: 3),

                ScaleTransition(
                  scale: logoScale,
                  child: FadeTransition(
                    opacity: logoFade,
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: gold.withOpacity(0.6),
                              width: 1.5,
                            ),
                            color: navyCard,
                          ),
                          child: Icon(Icons.anchor, color: gold, size: 40),
                        ),
                        SizedBox(height: 20),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 6,
                              color: textPrimary,
                            ),
                            children: [
                              TextSpan(text: 'MARINA'),
                              TextSpan(
                                text: 'HUB',
                                style: TextStyle(
                                  color: gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'ADMIN PORTAL',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 11,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Spacer(flex: 2),

                SlideTransition(
                  position: contentSlide,
                  child: FadeTransition(
                    opacity: contentFade,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        buildStatPill(Icons.location_on_outlined, 'Marinas'),
                        SizedBox(width: 12),
                        buildStatPill(Icons.directions_boat_outlined, 'Berths'),
                        SizedBox(width: 12),
                        buildStatPill(
                          Icons.calendar_today_outlined,
                          'Bookings',
                        ),
                        SizedBox(width: 12),
                        buildStatPill(Icons.people_outline, 'Users'),
                      ],
                    ),
                  ),
                ),

                Spacer(flex: 3),

                FadeTransition(
                  opacity: contentFade,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 60),
                    child: AnimatedBuilder(
                      animation: barProgress,
                      builder: (context, child) {
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: barProgress.value,
                                backgroundColor: navyCard,
                                valueColor: AlwaysStoppedAnimation<Color>(gold),
                                minHeight: 2,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              barProgress.value < 0.5
                                  ? 'Connecting...'
                                  : barProgress.value < 0.9
                                  ? 'Loading dashboard...'
                                  : 'Ready',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

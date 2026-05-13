import 'package:flutter/material.dart';
import 'package:marinahub/maps/maps.dart';
import 'package:marinahub/more/morePage.dart';
import 'package:marinahub/screens/bookings/booking.dart';
import 'package:marinahub/screens/homePage.dart';
import 'package:marinahub/screens/service/requestService.dart';

class DashboardScreen extends StatefulWidget {
  final int initialTab;
  const DashboardScreen({super.key, this.initialTab = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late int selectedNav;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<Widget> screens = [
    HomePage(),
    BoatMapScreen(),
    MyBookingsScreen(),
    requestService(),
    MorePage(),
  ];

  @override
  void initState() {
    super.initState();
    selectedNav = widget.initialTab;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == selectedNav) return;
    _controller.reverse().then((_) {
      setState(() => selectedNav = index);
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: screens[selectedNav],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF131C2B),
          border: Border(top: BorderSide(color: Color(0xFF243044), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedNav,
          onTap: _onNavTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFC9A84C),
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Maps'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handyman_outlined),
              label: 'Service',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.more), label: 'More'),
          ],
        ),
      ),
    );
  }
}

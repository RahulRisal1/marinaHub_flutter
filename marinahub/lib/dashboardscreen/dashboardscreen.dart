import 'package:flutter/material.dart';
import 'package:marinahub/screens/bookings/booking.dart';
import 'package:marinahub/screens/explore/exploreScreen.dart';
import 'package:marinahub/screens/homePage.dart';

import 'package:marinahub/screens/profile/profileScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedNav = 0;

  final List<Widget> screens = [
    HomePage(),
    exploreScreen(),
    bookingsScreen(),
    profileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: screens[selectedNav],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131C2B),
          border: Border(
            top: BorderSide(color: const Color(0xFF243044), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedNav,
          onTap: (index) => setState(() => selectedNav = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFC9A84C),
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

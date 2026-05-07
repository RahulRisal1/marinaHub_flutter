import 'package:flutter/material.dart';
import 'package:marinahub/splashscreen.dart';
import 'package:marinahub/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'accessToken',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NCwicm9sZSI6ImJvYXRlciIsImlhdCI6MTc3ODE1MjY2OSwiZXhwIjoxNzc4NzU3NDY5fQ.Z2TekYVgaxvWxIuE8bzClAmsc6b4cX2TajwC9s-aANs',
  );
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'fred',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColorOfApp,
          brightness: Brightness.light,
          primary: primaryColorOfApp,
        ),
      ),
      home: Splashscreen(),
    );
  }
}

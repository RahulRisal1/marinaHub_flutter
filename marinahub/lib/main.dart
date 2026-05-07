import 'package:flutter/material.dart';
import 'package:marinahub/splashscreen.dart';
import 'package:marinahub/utils/colors.dart';

void main() {
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

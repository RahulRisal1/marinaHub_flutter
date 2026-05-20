import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinahub/provider/userProvider.dart';
import 'package:marinahub/splashscreen.dart';
import 'package:marinahub/utils/colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // final prefs = await SharedPreferences.getInstance();
  // await prefs.setString(
  //   'accessToken',
  //   'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImU5MDk4NWFhLTFlNmQtNGRhNS1iYzA2LWQwNzU5MGRkZGFmNCIsInJvbGUiOiJhZG1pbiIsImlhdCI6MTc3ODUwMjE1NH0.xOunTZnf6CzO2gq0w0ytopGDsQXeU3sA9elXVJZoV0Y',
  // );

  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigationKey,
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

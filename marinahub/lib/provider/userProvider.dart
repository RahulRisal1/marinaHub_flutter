import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marinahub/Dio/myDio.dart';

class UserProvider extends ChangeNotifier {
  Map<dynamic, dynamic>? userData;

  Future<void> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userDataBox = await Hive.openBox("userDataBox");
    try {
      final response = await (await MyDio().getDio()).get("/users/me");
      final userList = response.data["user"] as List;
      if (userList.isEmpty) {
        debugPrint("⚠️ No user data returned from API");
        await loadUserDataFromHive();
        return;
      }
      final data = Map<dynamic, dynamic>.from(userList.first);
      await userDataBox.clear();
      await userDataBox.put("userData", data);
      userData = data;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint("❌ Error fetching user data: $e");
      debugPrint("📍 Stack trace: $stackTrace");
      await loadUserDataFromHive();
    }
  }

  Future<void> loadUserDataFromHive() async {
    final userDataBox = await Hive.openBox("userDataBox");
    final data = userDataBox.get("userData");
    if (data != null && data is Map) {
      debugPrint("📦 Loaded userData from Hive: $data");
      userData = Map<dynamic, dynamic>.from(data);
      notifyListeners();
    } else {
      debugPrint("⚠️ No cached userData found in Hive");
    }
  }

  Future<void> clearUserData() async {
    final userDataBox = await Hive.openBox("userDataBox");
    await userDataBox.clear();
    userData = null;
    notifyListeners();
  }

  bool get isLoggedIn => userData != null;
}

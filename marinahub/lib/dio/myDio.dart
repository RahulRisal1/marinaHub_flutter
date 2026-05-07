import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyDio {
  Future<Dio> getDio() async {
    String apiUrl = "http://localhost:3000/api/v1";
    // ";
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = await prefs.getString("accessToken");
    BaseOptions baseOptions = BaseOptions(
      baseUrl: "${apiUrl}",
      connectTimeout: Duration(seconds: 100),
      receiveTimeout: Duration(seconds: 100),
      headers: {"Authorization": "Bearer ${accessToken}"},
    );
    Dio dio = Dio(baseOptions);
    return dio;
  }
}

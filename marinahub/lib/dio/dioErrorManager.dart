import 'package:marinahub/dio/errorDialog.dart';
import 'package:marinahub/main.dart';

void dioErrorManager(dynamic e, {String? additionalText}) {
  try {
    if (e.response?.data != null) {
      MyDialog(
        context: navigationKey.currentContext, // ← remove !
        title: "Fail",
        message: e.response?.data["message"] ?? "Something went wrong",
        okText: "Ok",
      );
    } else {
      MyDialog(
        context: navigationKey.currentContext, // ← remove !
        title: "Connection Failed!",
        message:
            "${additionalText ?? ""}Please check your internet connection & try again",
        okText: "Ok",
      );
    }
  } catch (e) {
    MyDialog(
      context: navigationKey.currentContext,
      title: "Failed",
      message: "App has encountered an error. Please contact development team",
      okText: "Ok",
    );
  }
}

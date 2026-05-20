import 'package:flutter/material.dart';

import '../main.dart';

void MyDialog({
  BuildContext? context,
  required String title,
  required String message,
  required String okText,
}) {
  final ctx = navigationKey.currentContext;
  if (ctx == null) return;

  showDialog(
    context: ctx, // ← no ! force unwrap
    builder: (context) {
      return AlertDialog(
        actions: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                okText,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(message),
      );
    },
  );
}

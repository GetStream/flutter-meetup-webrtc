import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String?> displayTextInputDialog(
  BuildContext context, {
  required String title,
}) async {
  final TextEditingController textFieldController = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(controller: textFieldController),
        actions: <Widget>[
          TextButton(
            child: Text('CANCEL'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(context, textFieldController.text);
            },
          ),
        ],
      );
    },
  );
}

void copyToClipboard(String text) {
  log('copyToClipboard: $text');
  Clipboard.setData(ClipboardData(text: text));
}

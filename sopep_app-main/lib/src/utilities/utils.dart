// ignore: avoid_print
import 'package:flutter/material.dart';

void log(String text) => print("[FlutterReactiveBLEApp] $text");

// Function which acts like Toast in Android
void snackBar(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
    ),
  );
}

String cborToRegularTextString(Map<Object, Object> cbor) {
  String cborStr = cbor.toString();

  cborStr = cborStr.substring(1, cborStr.length - 1);
  cborStr = cborStr.replaceAll(', ', '\n');
  cborStr = cborStr.replaceAll(': ', '=');

  return cborStr;
}

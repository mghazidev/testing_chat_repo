import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../network/api_exceptions.dart';

void showApiError(dynamic e, {String? message}) {
  String title = 'API Error';
  String body = message ?? 'Something went wrong';

  if (e is ApiException) {
    body = e.message;
    if (e.statusCode != null) {
      body += ' (${e.statusCode})';
    }
    if (e.data != null) {
      try {
        final dataStr = e.data is Map ? e.data.toString() : e.data.toString();
        body += '\n\nResponse: $dataStr';
      } catch (_) {}
    }
  } else if (e is Exception || e != null) {
    body = e.toString();
  }

  Get.snackbar(
    title,
    body,
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(seconds: 5),
    backgroundColor: Colors.red.shade800,
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    isDismissible: true,
  );
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../domain/failures/failures.dart';
import 'html_plain_text.dart';

/// Maps API failures to translated snackbars / messages.
class ErrorFeedback {
  static bool isNetwork(Object error) {
    final message = error is RepositoryException
        ? error.message.toLowerCase()
        : error.toString().toLowerCase();
    return message.contains('network') ||
        message.contains('timeout') ||
        message.contains('socket') ||
        message.contains('connection refused') ||
        message.contains('connection reset');
  }

  static String message(Object error, {required String fallbackKey}) {
    if (isNetwork(error)) return 'connection_error'.tr;
    if (error is RepositoryException &&
        error.message.isNotEmpty &&
        error.message != 'Unknown response format') {
      final message = stripHtmlToPlainText(error.message);
      final limit = RegExp(
        r'Maximum Attachment Limit of\s+(\d+)',
        caseSensitive: false,
      ).firstMatch(message)?.group(1);
      if (limit != null) {
        return 'attachment_document_limit_reached'.trParams({'limit': limit});
      }
      if (message.isNotEmpty) return message;
    }
    return fallbackKey.tr;
  }

  static void snackbar(Object error, {required String fallbackKey}) {
    Get.snackbar(
      'error'.tr,
      message(error, fallbackKey: fallbackKey),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
    );
  }

  static void errorKey(String messageKey) {
    Get.snackbar(
      'error'.tr,
      messageKey.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
    );
  }
}

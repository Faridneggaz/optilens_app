import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../application/controllers/session_controller.dart';
import 'repository_exception.dart';

class InvalidSessionException extends RepositoryException {
  const InvalidSessionException() : super('Invalid session');
}

class AccessDeniedException extends RepositoryException {
  const AccessDeniedException() : super('Access denied');
}

/// Employee (`token` = login SID) API helpers.
class EmployeeApi {
  static bool _loggingOut = false;
  static DateTime? _lastAccessDeniedAt;

  static void resetAuthGuards() {
    _loggingOut = false;
  }

  /// Unwraps Frappe `{ message: ... }` and throws on `Invalid session` / `Access denied`.
  static dynamic unwrap(dynamic decoded) {
    final message = decoded is Map && decoded.containsKey('message')
        ? decoded['message']
        : decoded;
    if (message is Map) {
      final error = message['error']?.toString();
      if (error != null && error.isNotEmpty) {
        throwForError(error);
      }
    }
    return message;
  }

  static dynamic unwrapBody(String body) => unwrap(json.decode(body));

  static dynamic unwrapResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw RepositoryException('Server error: ${response.statusCode}');
    }
    return unwrapBody(response.body);
  }

  static void throwForError(String error) {
    if (error == 'Invalid session') {
      _logoutInvalidSession();
      throw const InvalidSessionException();
    }
    if (error == 'Access denied') {
      _showAccessDenied();
      throw const AccessDeniedException();
    }
    throw RepositoryException(error);
  }

  static Map<String, dynamic> failureResult(Object e) {
    if (e is InvalidSessionException || e is AccessDeniedException) {
      return {'_auth': true};
    }
    return {'error': e.toString()};
  }

  static bool isAuthHandled(Map<String, dynamic> result) =>
      result['_auth'] == true;

  static void _logoutInvalidSession() {
    if (_loggingOut) return;
    _loggingOut = true;
    if (Get.isRegistered<SessionController>()) {
      Get.find<SessionController>().logout();
    }
  }

  static void _showAccessDenied() {
    final now = DateTime.now();
    if (_lastAccessDeniedAt != null &&
        now.difference(_lastAccessDeniedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastAccessDeniedAt = now;
    Get.snackbar(
      'error'.tr,
      'error_access_denied'.tr,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

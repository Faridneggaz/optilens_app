import 'dart:convert';

import '../auth/auth_events.dart';
import '../../domain/failures/failures.dart';

/// Unwraps Frappe `{ message: ... }` without UI dependencies.
class FrappeMessage {
  static dynamic unwrap(dynamic decoded) {
    if (decoded is Map) {
      final fault = exceptionMessage(decoded);
      if (fault != null) {
        throwForError(fault);
      }
    }
    final message = decoded is Map && decoded.containsKey('message')
        ? decoded['message']
        : decoded;
    if (message is Map) {
      final nestedFault = exceptionMessage(message);
      if (nestedFault != null) {
        throwForError(nestedFault);
      }
      final error = message['error']?.toString();
      if (error != null && error.isNotEmpty && error != 'null') {
        throwForError(error);
      }
    }
    return message;
  }

  /// Readable Frappe traceback / `_server_messages` when the call failed.
  static String? exceptionMessage(Map map) {
    final hasException = map['exception'] != null ||
        (map['exc'] != null && '${map['exc']}'.trim().isNotEmpty) ||
        map['exc_type'] != null;
    if (!hasException) return null;
    final server = parseServerMessages(map['_server_messages']);
    if (server != null && server.isNotEmpty) {
      return server;
    }
    final exception = map['exception']?.toString();
    if (exception != null && exception.trim().isNotEmpty) {
      return _shortException(exception);
    }
    return null;
  }

  static String? parseServerMessages(dynamic raw) {
    if (raw == null) return null;
    try {
      final decoded = raw is String ? json.decode(raw) : raw;
      final parts = <String>[];
      final list = decoded is List ? decoded : [decoded];
      for (final item in list) {
        dynamic value = item;
        if (value is String) {
          try {
            value = json.decode(value);
          } catch (_) {}
        }
        if (value is Map) {
          final text = (value['message'] ?? value['title'] ?? '').toString();
          if (text.trim().isNotEmpty) parts.add(text.trim());
        } else if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) parts.add(text);
        }
      }
      if (parts.isEmpty) return null;
      return parts.join('\n');
    } catch (_) {
      final text = raw.toString().trim();
      return text.isEmpty ? null : text;
    }
  }

  static String _shortException(String exception) {
    final cleaned = exception
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return exception.trim();
    final last = cleaned.last;
    final prefix = last.split(':');
    if (prefix.length >= 2) {
      return prefix.sublist(1).join(':').trim();
    }
    return last;
  }

  static dynamic unwrapBody(String body) => unwrap(json.decode(body));

  static void throwForError(String error) {
    if (error == 'Invalid session') {
      AuthEvents.notifyInvalidSession();
      throw const InvalidSessionException();
    }
    if (error == 'Access denied') {
      AuthEvents.notifyAccessDenied();
      throw const AccessDeniedException();
    }
    throw RepositoryException(error);
  }
}

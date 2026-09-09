import 'dart:convert';

import '../auth/auth_events.dart';
import '../../domain/failures/failures.dart';

/// Unwraps Frappe `{ message: ... }` without UI dependencies.
class FrappeMessage {
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

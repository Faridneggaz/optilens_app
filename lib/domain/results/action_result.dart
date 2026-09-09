import '../failures/failures.dart';

/// Typed outcome for employee actions (submit, delete, approve, create).
class ActionResult {
  const ActionResult._({
    required this.isSuccess,
    required this.isAuthHandled,
    this.error,
    this.message,
    this.detail,
    this.documentName,
    this.stockEntryId,
  });

  final bool isSuccess;
  final bool isAuthHandled;
  final String? error;
  final String? message;
  final String? detail;
  final String? documentName;
  final String? stockEntryId;

  factory ActionResult.ok({
    String? message,
    String? detail,
    String? documentName,
    String? stockEntryId,
  }) {
    return ActionResult._(
      isSuccess: true,
      isAuthHandled: false,
      message: message,
      detail: detail,
      documentName: documentName,
      stockEntryId: stockEntryId,
    );
  }

  factory ActionResult.failure(String error) {
    return ActionResult._(
      isSuccess: false,
      isAuthHandled: false,
      error: error,
    );
  }

  factory ActionResult.authHandled() {
    return const ActionResult._(isSuccess: false, isAuthHandled: true);
  }

  factory ActionResult.fromException(Object e) {
    if (e is InvalidSessionException || e is AccessDeniedException) {
      return ActionResult.authHandled();
    }
    return ActionResult.failure(e.toString());
  }

  factory ActionResult.fromApiMap(Map<String, dynamic> map) {
    final nested = map['message'];
    String? nestedName;
    if (nested is Map) {
      nestedName = nested['name']?.toString();
    }

    final name =
        map['name']?.toString() ?? map['id']?.toString() ?? nestedName;
    final stockId = map['stock_entry_id']?.toString();
    final error = map['error']?.toString();
    final successFlag = map['success'] == true;
    final messageOk = map['message'] == 'Success';

    if (error != null &&
        error.isNotEmpty &&
        !successFlag &&
        !messageOk &&
        name == null &&
        stockId == null) {
      return ActionResult.failure(error);
    }

    if (messageOk || successFlag || name != null || stockId != null) {
      return ActionResult.ok(
        message: nested is String ? nested : (messageOk ? 'Success' : null),
        detail: map['detail']?.toString(),
        documentName: name,
        stockEntryId: stockId,
      );
    }

    return ActionResult.failure(error ?? 'Unknown response format');
  }
}

class ChangeCodeResult {
  const ChangeCodeResult({required this.success, this.error});

  final bool success;
  final String? error;
}

class MissingTokenException extends RepositoryException {
  const MissingTokenException() : super('Token missing');
}

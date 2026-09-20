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
    return ActionResult.failure(
      e is RepositoryException ? e.message : e.toString(),
    );
  }

  /// Stock Entry name if the payload has one (never a Material Request name).
  String? get navigableStockEntryId {
    final id = stockEntryId ?? documentName;
    if (id == null || id.isEmpty || id == 'Success') return null;
    final upper = id.toUpperCase();
    if (upper.contains('MAT-MR') && !upper.contains('STE')) return null;
    return id;
  }

  factory ActionResult.fromApiMap(Map<String, dynamic> map) {
    final nested = map['message'];
    String? nestedName;
    if (nested is Map) {
      nestedName = _documentNameFrom(nested);
    } else if (nested is String &&
        nested.isNotEmpty &&
        nested != 'Success' &&
        !nested.toLowerCase().startsWith('error')) {
      nestedName = nested;
    }

    final name = _documentNameFrom(map) ?? nestedName;
    final stockId = _stockEntryIdFrom(map, nested);
    final error = map['error']?.toString();
    final rawSuccess = map['success'];
    final successFlag = rawSuccess == true ||
        rawSuccess == 1 ||
        rawSuccess == '1' ||
        rawSuccess == 'true';
    final messageOk = map['message'] == 'Success' ||
        map['status'] == 'success';

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

  static String? _documentNameFrom(Map map) {
    for (final key in [
      'name',
      'id',
      'material_request',
      'docname',
      'document_name',
    ]) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _stockEntryIdFrom(Map<String, dynamic> map, dynamic nested) {
    final nestedMap = nested is Map ? nested : null;
    final candidates = <dynamic>[
      map['stock_entry_id'],
      map['stock_entry_name'],
      nestedMap?['stock_entry_id'],
      if (map['stock_entry'] is String) map['stock_entry'],
      if (map['stock_entry'] is Map) map['stock_entry']['name'],
      if (nestedMap?['stock_entry'] is String) nestedMap?['stock_entry'],
      if (nestedMap?['stock_entry'] is Map) nestedMap?['stock_entry']['name'],
      if (nested is String) nested,
      map['name'],
      nestedMap?['name'],
    ];
    for (final value in candidates) {
      final id = value?.toString().trim() ?? '';
      if (id.isEmpty || id == 'Success') continue;
      if (id.toUpperCase().contains('STE')) return id;
    }
    for (final value in [
      map['stock_entry_id'],
      if (map['stock_entry'] is String) map['stock_entry'],
      if (map['stock_entry'] is Map) map['stock_entry']['name'],
    ]) {
      final id = value?.toString().trim() ?? '';
      if (id.isNotEmpty && id != 'Success') return id;
    }
    return null;
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

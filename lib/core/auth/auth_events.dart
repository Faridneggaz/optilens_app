/// Presentation registers these so the data/network layer never imports GetX.
class AuthEvents {
  AuthEvents._();

  static void Function()? onInvalidSession;
  static void Function()? onAccessDenied;
  static bool _loggingOut = false;
  static DateTime? _lastAccessDeniedAt;

  static void resetGuards() {
    _loggingOut = false;
  }

  static void notifyInvalidSession() {
    if (_loggingOut) return;
    _loggingOut = true;
    onInvalidSession?.call();
  }

  static void notifyAccessDenied() {
    final now = DateTime.now();
    if (_lastAccessDeniedAt != null &&
        now.difference(_lastAccessDeniedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastAccessDeniedAt = now;
    onAccessDenied?.call();
  }
}

class RepositoryException implements Exception {
  final String message;
  const RepositoryException(this.message);

  @override
  String toString() => 'RepositoryException: $message';
}

class InvalidSessionException extends RepositoryException {
  const InvalidSessionException() : super('Invalid session');
}

class AccessDeniedException extends RepositoryException {
  const AccessDeniedException() : super('Access denied');
}

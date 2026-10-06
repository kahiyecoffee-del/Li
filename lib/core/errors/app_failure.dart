/// User-presentable failure categories. Raw exceptions are never shown; the
/// UI maps these to friendly localized messages (see `failureMessage`).
enum FailureKind {
  network,
  timeout,
  unavailable,
  quotaExceeded,
  rateLimited,
  unauthenticated,
  permissionDenied,
  invalidInput,
  cancelled,
  emailInUse,
  wrongCredentials,
  weakPassword,
  requiresRecentLogin,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure(this.kind, {this.cause, this.details = const {}});

  final FailureKind kind;
  final Object? cause;

  /// Extra machine-readable context (e.g. remaining credits).
  final Map<String, Object?> details;

  @override
  String toString() => 'AppFailure($kind, $cause)';
}

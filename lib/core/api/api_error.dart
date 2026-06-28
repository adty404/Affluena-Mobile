class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.path});

  final String message;
  final int? statusCode;
  final String? path;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' ($statusCode)';
    return 'ApiException$status: $message';
  }
}

class SessionExpiredException extends ApiException {
  const SessionExpiredException({super.path})
    : super(message: 'Sesi berakhir. Silakan masuk lagi.', statusCode: 401);
}

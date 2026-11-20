class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException(${code ?? 'ERROR'}): $message';
}

class ValidationException extends AppException {
  const ValidationException(super.message) : super(code: 'VALIDATION_ERROR');
}

class DataIntegrityException extends AppException {
  const DataIntegrityException(super.message) : super(code: 'DATA_INTEGRITY');
}

class NotFoundException extends AppException {
  const NotFoundException(super.message) : super(code: 'NOT_FOUND');
}

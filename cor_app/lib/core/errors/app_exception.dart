/// Exceção base do aplicativo
class AppException implements Exception {
  final String message;
  final dynamic originalError;

  AppException(this.message, {this.originalError});

  @override
  String toString() => message;
}

/// Erro de rede/conexão
class NetworkException extends AppException {
  NetworkException(super.message, {super.originalError});
}

/// Erro de API genérico
class ApiException extends AppException {
  final int? statusCode;

  ApiException(super.message, {this.statusCode, super.originalError});
}

/// Recurso não encontrado (404)
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.originalError});
}

/// Não autorizado (401/403)
class UnauthorizedException extends AppException {
  UnauthorizedException(super.message, {super.originalError});
}

/// Erro de validação (422)
class ValidationException extends AppException {
  ValidationException(super.message, {super.originalError});
}

/// Erro do servidor (5xx)
class ServerException extends AppException {
  ServerException(super.message, {super.originalError});
}

/// Erro de localização/GPS
class LocationException extends AppException {
  LocationException(super.message, {super.originalError});
}

/// Erro de permissão
class PermissionException extends AppException {
  PermissionException(super.message, {super.originalError});
}

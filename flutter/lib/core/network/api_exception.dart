sealed class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  const factory ApiException.timeout() = TimeoutException;
  const factory ApiException.noConnection() = NoConnectionException;
  const factory ApiException.cancelled() = CancelledException;
  const factory ApiException.unauthorized() = UnauthorizedException;
  const factory ApiException.forbidden() = ForbiddenException;
  const factory ApiException.notFound(String message) = NotFoundException;
  const factory ApiException.badRequest(String message) = BadRequestException;
  const factory ApiException.validationError(String message) = ValidationException;
  const factory ApiException.rateLimited() = RateLimitedException;
  const factory ApiException.serverError(String message) = ServerException;
  const factory ApiException.unknown(String message) = UnknownException;

  @override
  String toString() => 'ApiException: $message';
}

class TimeoutException extends ApiException {
  const TimeoutException() : super('Connection timed out');
}

class NoConnectionException extends ApiException {
  const NoConnectionException() : super('No internet connection');
}

class CancelledException extends ApiException {
  const CancelledException() : super('Request was cancelled');
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException() : super('Unauthorized');
}

class ForbiddenException extends ApiException {
  const ForbiddenException() : super('Access forbidden');
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message);
}

class BadRequestException extends ApiException {
  const BadRequestException(super.message);
}

class ValidationException extends ApiException {
  const ValidationException(super.message);
}

class RateLimitedException extends ApiException {
  const RateLimitedException() : super('Too many requests');
}

class ServerException extends ApiException {
  const ServerException(super.message);
}

class UnknownException extends ApiException {
  const UnknownException(super.message);
}

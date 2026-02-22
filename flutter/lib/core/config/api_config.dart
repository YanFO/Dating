abstract final class ApiConfig {
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 120);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  static const String contentTypeJson = 'application/json';
  static const String contentTypeMultipart = 'multipart/form-data';

  static const Map<String, String> defaultHeaders = {
    'Accept': contentTypeJson,
    'Content-Type': contentTypeJson,
  };
}

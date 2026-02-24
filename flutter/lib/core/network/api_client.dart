import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../config/api_config.dart';
import '../constants/api_endpoints.dart';
import 'api_exception.dart';

typedef ApiResult<T> = Future<Either<ApiException, T>>;

class ApiClient {
  late final Dio _dio;
  String? Function()? _tokenGetter;

  ApiClient({String? Function()? tokenGetter}) : _tokenGetter = tokenGetter {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.defaultHeaders,
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(this),
      _LoggingInterceptor(),
      _RetryInterceptor(_dio),
    ]);
  }

  /// Update the token getter (called when auth state changes).
  set tokenGetter(String? Function()? getter) => _tokenGetter = getter;

  Dio get dio => _dio;

  ApiResult<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return Right(_parseResponse(response.data, fromJson));
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  ApiResult<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return Right(_parseResponse(response.data, fromJson));
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  ApiResult<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return Right(_parseResponse(response.data, fromJson));
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  ApiResult<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return Right(_parseResponse(response.data, fromJson));
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  ApiResult<T> uploadFile<T>(
    String path, {
    required Uint8List bytes,
    required String filename,
    required String fieldName,
    Map<String, dynamic>? extraFields,
    T Function(dynamic)? fromJson,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
        ...?extraFields,
      });

      final response = await _dio.post<dynamic>(
        path,
        data: formData,
        options: Options(
          contentType: ApiConfig.contentTypeMultipart,
        ),
        onSendProgress: onSendProgress,
      );
      return Right(_parseResponse(response.data, fromJson));
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  ApiResult<T> uploadFiles<T>(
    String path, {
    required List<Uint8List> bytesList,
    required List<String> filenames,
    required String fieldName,
    Map<String, dynamic>? extraFields,
    T Function(dynamic)? fromJson,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final formData = FormData();
      for (var i = 0; i < bytesList.length; i++) {
        formData.files.add(MapEntry(
          fieldName,
          MultipartFile.fromBytes(
            bytesList[i],
            filename: filenames[i],
          ),
        ));
      }
      if (extraFields != null) {
        extraFields.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _dio.post<dynamic>(
        path,
        data: formData,
        options: Options(
          contentType: ApiConfig.contentTypeMultipart,
        ),
        onSendProgress: onSendProgress,
      );
      return Right(_parseResponse(response.data, fromJson));
    } on DioException catch (e) {
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(ApiException.unknown(e.toString()));
    }
  }

  T _parseResponse<T>(dynamic data, T Function(dynamic)? fromJson) {
    if (fromJson != null) {
      return fromJson(data);
    }
    return data as T;
  }

  ApiException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException.timeout();
      case DioExceptionType.connectionError:
        return const ApiException.noConnection();
      case DioExceptionType.badResponse:
        return _handleBadResponse(e.response);
      case DioExceptionType.cancel:
        return const ApiException.cancelled();
      default:
        return ApiException.unknown(e.message ?? 'Unknown error');
    }
  }

  ApiException _handleBadResponse(Response<dynamic>? response) {
    if (response == null) {
      return const ApiException.unknown('No response received');
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;
    String? message;

    if (data is Map<String, dynamic>) {
      // Try to get message directly
      message = data['message'] as String?;

      // If not found, check if error is a string or an object with message
      if (message == null && data['error'] != null) {
        final error = data['error'];
        if (error is String) {
          message = error;
        } else if (error is Map<String, dynamic>) {
          message = error['message'] as String?;
        }
      }
    }

    switch (statusCode) {
      case 400:
        return ApiException.badRequest(message ?? 'Bad request');
      case 401:
        return const ApiException.unauthorized();
      case 403:
        return const ApiException.forbidden();
      case 404:
        return ApiException.notFound(message ?? 'Resource not found');
      case 422:
        return ApiException.validationError(message ?? 'Validation failed');
      case 429:
        return const ApiException.rateLimited();
      case >= 500:
        return ApiException.serverError(message ?? 'Server error');
      default:
        return ApiException.unknown('HTTP $statusCode: $message');
    }
  }

  void dispose() {
    _dio.close();
  }
}

class _AuthInterceptor extends Interceptor {
  final ApiClient _client;

  _AuthInterceptor(this._client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _client._tokenGetter?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('[API] ➡️ ${options.method} ${options.uri}');
    print('[API]    Headers: ${options.headers}');
    if (options.queryParameters.isNotEmpty) {
      print('[API]    Query: ${options.queryParameters}');
    }
    if (options.data != null) {
      print('[API]    Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('[API] ✅ ${response.statusCode} ${response.requestOptions.uri}');
    print('[API]    Response: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('[API] ❌ ERROR: ${err.type} ${err.requestOptions.uri}');
    print('[API]    Status: ${err.response?.statusCode}');
    print('[API]    Message: ${err.message}');
    print('[API]    Response: ${err.response?.data}');
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int _maxRetries = ApiConfig.maxRetryAttempts;

  _RetryInterceptor(this._dio);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

      if (retryCount < _maxRetries) {
        await Future.delayed(ApiConfig.retryDelay * (retryCount + 1));

        try {
          err.requestOptions.extra['retryCount'] = retryCount + 1;
          final response = await _dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          // Continue to error handler
        }
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

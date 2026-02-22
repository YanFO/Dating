/// SSE（Server-Sent Events）串流客戶端
///
/// 在 Web 平台使用瀏覽器原生 fetch API + ReadableStream 接收 SSE 串流，
/// 在原生平台使用 Dio 的 ResponseType.stream。
/// 逐步解析文字 chunk 並透過 Stream<String> 產出。

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/api_config.dart';
import '../constants/api_endpoints.dart';
import 'sse_client_web.dart' if (dart.library.io) 'sse_client_native.dart'
    as platform;

class SseClient {
  late final Dio _dio;

  SseClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Accept': 'text/event-stream',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// 發送 POST 請求並回傳 SSE 文字 chunk 串流。
  Stream<String> postStream(
    String path, {
    required Map<String, dynamic> data,
    CancelToken? cancelToken,
  }) {
    final controller = StreamController<String>();

    if (kIsWeb) {
      final url = '${ApiEndpoints.baseUrl}$path';
      platform.startWebStreaming(url, data, cancelToken, controller);
    } else {
      _startNativeStreaming(path, data, cancelToken, controller);
    }

    return controller.stream;
  }

  /// 原生平台的 SSE 串流實作
  Future<void> _startNativeStreaming(
    String path,
    Map<String, dynamic> data,
    CancelToken? cancelToken,
    StreamController<String> controller,
  ) async {
    try {
      final response = await _dio.post<ResponseBody>(
        path,
        data: data,
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      final stream = response.data!.stream;
      String buffer = '';
      final decoder = Utf8Decoder(allowMalformed: true);

      await for (final chunk in stream) {
        final bytes = decoder.convert(chunk);
        buffer += bytes;
        parseSseBuffer(buffer, controller, (rest) => buffer = rest);
        if (controller.isClosed) return;
      }

      if (!controller.isClosed) {
        await controller.close();
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        if (!controller.isClosed) await controller.close();
      } else {
        if (!controller.isClosed) {
          controller.addError(e);
          await controller.close();
        }
      }
    } catch (e) {
      if (!controller.isClosed) {
        controller.addError(e);
        await controller.close();
      }
    }
  }

  void dispose() {
    _dio.close();
  }

  /// 解析 SSE buffer，提取完整訊息並推送至 controller。
  /// 共用邏輯，供原生與 Web 平台使用。
  static void parseSseBuffer(
    String buffer,
    StreamController<String> controller,
    void Function(String remaining) setBuffer,
  ) {
    while (buffer.contains('\n\n')) {
      final index = buffer.indexOf('\n\n');
      final message = buffer.substring(0, index);
      buffer = buffer.substring(index + 2);

      bool isDone = false;
      bool isError = false;
      final dataLines = <String>[];

      for (final line in message.split('\n')) {
        if (line.startsWith('event: done')) {
          isDone = true;
        } else if (line.startsWith('event: error')) {
          isError = true;
        } else if (line.startsWith('data: ')) {
          dataLines.add(line.substring(6));
        } else if (line.startsWith('data:')) {
          dataLines.add(line.substring(5));
        }
      }

      final payload = dataLines.join('\n');

      if (payload == '[DONE]') {
        isDone = true;
      } else if (isDone) {
        controller.add('__DONE__$payload');
      } else if (isError) {
        controller.addError(Exception(payload));
      } else if (payload.isNotEmpty) {
        controller.add(payload);
      }

      if (isDone && !controller.isClosed) {
        controller.close();
        setBuffer(buffer);
        return;
      }
    }
    setBuffer(buffer);
  }
}

/// SSE 串流的 Web 平台實作
///
/// 使用瀏覽器原生 fetch API + ReadableStream 實現真正的串流接收。
/// Dio 在 Web 上使用 XMLHttpRequest，無法串流。

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'sse_client.dart';

/// Web 平台的 SSE 串流啟動函數
void startWebStreaming(
  String url,
  Map<String, dynamic> data,
  CancelToken? cancelToken,
  StreamController<String> controller,
) {
  _doWebStreaming(url, data, cancelToken, controller);
}

Future<void> _doWebStreaming(
  String url,
  Map<String, dynamic> data,
  CancelToken? cancelToken,
  StreamController<String> controller,
) async {
  web.AbortController? abortController;

  try {
    abortController = web.AbortController();
    debugPrint('[SSE-Web] Starting fetch to $url');

    // 若有 CancelToken，監聯取消事件
    cancelToken?.whenCancel.then((_) {
      debugPrint('[SSE-Web] CancelToken triggered, aborting');
      abortController?.abort();
      if (!controller.isClosed) controller.close();
    });

    final body = jsonEncode(data);

    final headers = web.Headers();
    headers.set('Content-Type', 'application/json');
    headers.set('Accept', 'text/event-stream');

    final init = web.RequestInit(
      method: 'POST',
      headers: headers,
      body: body.toJS,
      signal: abortController.signal,
    );

    final response = await web.window.fetch(url.toJS, init).toDart;
    debugPrint('[SSE-Web] Response status: ${response.status}');

    if (!response.ok) {
      debugPrint('[SSE-Web] Response not OK: ${response.status}');
      if (!controller.isClosed) {
        controller.addError(Exception('HTTP ${response.status}'));
        await controller.close();
      }
      return;
    }

    final readableStream = response.body;
    if (readableStream == null) {
      debugPrint('[SSE-Web] No response body (ReadableStream is null)');
      if (!controller.isClosed) {
        controller.addError(Exception('No response body'));
        await controller.close();
      }
      return;
    }

    debugPrint('[SSE-Web] Got ReadableStream, starting to read chunks...');
    final reader = readableStream.getReader() as web.ReadableStreamDefaultReader;
    final decoder = const Utf8Decoder(allowMalformed: true);
    String buffer = '';
    int chunkCount = 0;

    while (true) {
      final result = await reader.read().toDart;

      if (result.done) {
        debugPrint('[SSE-Web] ReadableStream done after $chunkCount chunks');
        break;
      }

      final chunk = result.value;
      if (chunk == null) continue;

      chunkCount++;
      final jsArray = chunk as JSUint8Array;
      final bytes = jsArray.toDart;
      final text = decoder.convert(bytes);
      buffer += text;

      debugPrint('[SSE-Web] Chunk #$chunkCount (${bytes.length} bytes): ${text.substring(0, text.length > 60 ? 60 : text.length)}');

      SseClient.parseSseBuffer(buffer, controller, (rest) => buffer = rest);

      if (controller.isClosed) {
        debugPrint('[SSE-Web] Controller closed after chunk #$chunkCount');
        return;
      }
    }

    if (!controller.isClosed) {
      debugPrint('[SSE-Web] Closing controller normally');
      await controller.close();
    }
  } catch (e, st) {
    debugPrint('[SSE-Web] Error: $e');
    debugPrint('[SSE-Web] Stack: $st');
    if (e.toString().contains('AbortError')) {
      if (!controller.isClosed) await controller.close();
    } else {
      if (!controller.isClosed) {
        controller.addError(e);
        await controller.close();
      }
    }
  }
}

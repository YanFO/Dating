/// SSE 串流的原生平台存根
///
/// 原生平台使用 Dio 的 ResponseType.stream（在 SseClient 內直接處理），
/// 此檔案僅提供 startWebStreaming 的存根以滿足條件導入。

import 'dart:async';

import 'package:dio/dio.dart';

void startWebStreaming(
  String url,
  Map<String, dynamic> data,
  CancelToken? cancelToken,
  StreamController<String> controller,
) {
  // 原生平台不應走到這裡，由 SseClient 的 kIsWeb 分支控制
  throw UnsupportedError('Web streaming is not supported on native platforms');
}

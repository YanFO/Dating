/// Love Coach 聊天狀態管理
///
/// 使用 Riverpod StateNotifier 管理聊天面板狀態，
/// 包含訊息列表、串流狀態、對話 ID 等。
/// 透過 SseClient 與後端 SSE 端點互動，實現即時串流回覆。

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/sse_client.dart';
import '../../data/models/love_coach_models.dart';
import 'core_providers.dart';

// ─── 狀態定義 ─────────────────────────────────────

/// Love Coach 聊天面板的完整狀態
class LoveCoachState {
  /// 聊天訊息列表（含使用者與 AI 回覆）
  final List<LoveCoachMessage> messages;

  /// 是否正在串流回覆中
  final bool isStreaming;

  /// 串流中的部分回覆文字（尚未完成的 AI 回覆）
  final String streamingText;

  /// 當前對話 ID（由後端回傳，用於持久化）
  final String? conversationId;

  /// 錯誤訊息（發生錯誤時顯示）
  final String? errorMessage;

  /// 是否正在載入歷史記錄
  final bool isLoadingHistory;

  const LoveCoachState({
    this.messages = const [],
    this.isStreaming = false,
    this.streamingText = '',
    this.conversationId,
    this.errorMessage,
    this.isLoadingHistory = false,
  });

  /// 建立狀態副本，僅更新指定欄位
  LoveCoachState copyWith({
    List<LoveCoachMessage>? messages,
    bool? isStreaming,
    String? streamingText,
    String? conversationId,
    String? errorMessage,
    bool? isLoadingHistory,
    bool clearError = false,
  }) {
    return LoveCoachState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingText: streamingText ?? this.streamingText,
      conversationId: conversationId ?? this.conversationId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }
}

// ─── 狀態管理器 ───────────────────────────────────

class LoveCoachNotifier extends StateNotifier<LoveCoachState> {
  final SseClient _sse;
  final ApiClient _api;
  CancelToken? _cancelToken;
  StreamSubscription<String>? _streamSub;

  LoveCoachNotifier(this._sse, this._api) : super(const LoveCoachState());

  /// 傳送訊息並串流接收 AI 回覆
  ///
  /// 流程：
  /// 1. 新增使用者訊息至列表
  /// 2. 設定串流狀態
  /// 3. 透過 SSE 發送請求
  /// 4. 逐步累積回覆文字
  /// 5. 串流結束後將完整回覆加入訊息列表
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isStreaming) return;

    // 新增使用者訊息
    final userMsg = LoveCoachMessage(
      role: 'user',
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isStreaming: true,
      streamingText: '',
      clearError: true,
    );

    _cancelToken = CancelToken();

    try {
      final stream = _sse.postStream(
        ApiEndpoints.loveCoachChat,
        data: {
          'message': text.trim(),
          'conversation_id': state.conversationId,
        },
        cancelToken: _cancelToken,
      );

      String fullResponse = '';

      debugPrint('[LoveCoach] Subscribing to SSE stream...');

      _streamSub = stream.listen(
        (chunk) {
          // 檢查是否為 done 事件（包含 conversation_id）
          if (chunk.startsWith('__DONE__')) {
            debugPrint('[LoveCoach] Got __DONE__ event');
            final metadata = chunk.substring(8);
            try {
              final json = jsonDecode(metadata) as Map<String, dynamic>;
              final convId = json['conversation_id'] as String?;
              if (convId != null) {
                state = state.copyWith(conversationId: convId);
              }
            } catch (_) {}
            return;
          }

          // 累積文字 chunk
          fullResponse += chunk;
          debugPrint('[LoveCoach] Chunk received (${chunk.length} chars), total: ${fullResponse.length}');
          state = state.copyWith(streamingText: fullResponse);
        },
        onError: (error) {
          debugPrint('[LoveCoach] Stream error: $error');
          if (error is DioException && error.type == DioExceptionType.cancel) {
            state = state.copyWith(isStreaming: false, streamingText: '');
            return;
          }
          state = state.copyWith(
            isStreaming: false,
            streamingText: '',
            errorMessage: '連線錯誤，請稍後重試',
          );
        },
        onDone: () {
          debugPrint('[LoveCoach] Stream done, fullResponse length: ${fullResponse.length}');
          if (fullResponse.isNotEmpty) {
            final modelMsg = LoveCoachMessage(
              role: 'model',
              text: fullResponse,
              timestamp: DateTime.now(),
            );
            state = state.copyWith(
              messages: [...state.messages, modelMsg],
              isStreaming: false,
              streamingText: '',
            );
          } else {
            state = state.copyWith(isStreaming: false, streamingText: '');
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isStreaming: false,
        streamingText: '',
        errorMessage: '無法連線至伺服器',
      );
    }
  }

  /// 取消正在進行的串流
  void cancelStream() {
    _cancelToken?.cancel();
    _cancelToken = null;
    _streamSub?.cancel();
    _streamSub = null;
    state = state.copyWith(isStreaming: false, streamingText: '');
  }

  /// 從後端載入對話歷史
  Future<void> loadConversation(String conversationId) async {
    state = state.copyWith(isLoadingHistory: true, clearError: true);

    final result = await _api.get<dynamic>(
      '${ApiEndpoints.loveCoach}/conversations/$conversationId/messages',
    );

    result.fold(
      (error) {
        state = state.copyWith(
          isLoadingHistory: false,
          errorMessage: '載入歷史記錄失敗',
        );
      },
      (data) {
        // 從後端 envelope 解開 data 欄位
        final rawData = data is Map<String, dynamic> ? data['data'] : data;
        final List<dynamic> msgList = rawData is List ? rawData : [];
        final messages = msgList
            .map((m) =>
                LoveCoachMessage.fromJson(m as Map<String, dynamic>))
            .toList();

        state = state.copyWith(
          messages: messages,
          conversationId: conversationId,
          isLoadingHistory: false,
        );
      },
    );
  }

  /// 清除所有聊天記錄（僅清除前端狀態，不刪除後端資料）
  void clearHistory() {
    cancelStream();
    state = const LoveCoachState();
  }

  /// 開始新對話（清除前端狀態與 conversationId）
  void startNewConversation() {
    cancelStream();
    state = const LoveCoachState();
  }

  @override
  void dispose() {
    cancelStream();
    super.dispose();
  }
}

// ─── Provider 定義 ────────────────────────────────

/// SSE 客戶端 Provider（全域單例）
final sseClientProvider = Provider<SseClient>((ref) {
  final client = SseClient();
  ref.onDispose(() => client.dispose());
  return client;
});

/// Love Coach 狀態 Provider
final loveCoachProvider =
    StateNotifierProvider<LoveCoachNotifier, LoveCoachState>((ref) {
  return LoveCoachNotifier(
    ref.read(sseClientProvider),
    ref.read(apiClientProvider),
  );
});

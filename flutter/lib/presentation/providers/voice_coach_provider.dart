// 語音教練狀態管理
//
// 管理 WebSocket 連線、錄音串流、即時語音辨識、情緒分析與教練建議的完整狀態。
// 透過 Riverpod StateNotifier 提供響應式 UI 更新。
//
// 錄音使用跨平台抽象層：
// - Web: WebAudioRecorder (AudioWorklet → PCM16 24kHz)
// - Native: record 套件的 AudioRecorder

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/audio/audio_recorder_factory.dart';
import '../../core/network/voice_coach_ws.dart';

/// 語音教練連線狀態
enum VoiceCoachStatus { disconnected, connecting, connected, error }

/// 語音教練完整狀態
class VoiceCoachState {
  final VoiceCoachStatus status;
  final bool isRecording;
  final bool userSpeaking;

  /// AI 教練語音的即時轉寫（流式累加）
  final String transcript;

  /// 麥克風收音的即時辨識結果列表（每句完成後加入）
  final List<String> inputTranscripts;

  /// 對方目前偵測到的情緒標籤
  final String emotion;

  /// 情緒的簡短說明
  final String emotionDetail;

  /// 結構化的下一句建議列表
  final List<String> coachingSuggestions;

  /// 接下來的聊天方向建議
  final String direction;

  /// 本次建議使用的核心技巧名稱（推拉、reframing、冷讀假設等）
  final String technique;

  /// 純文字建議（後備用，當 JSON 解析失敗時使用）
  final List<String> suggestions;

  final String? sessionId;
  final String? errorMessage;

  const VoiceCoachState({
    this.status = VoiceCoachStatus.disconnected,
    this.isRecording = false,
    this.userSpeaking = false,
    this.transcript = '',
    this.inputTranscripts = const [],
    this.emotion = '',
    this.emotionDetail = '',
    this.coachingSuggestions = const [],
    this.direction = '',
    this.technique = '',
    this.suggestions = const [],
    this.sessionId,
    this.errorMessage,
  });

  VoiceCoachState copyWith({
    VoiceCoachStatus? status,
    bool? isRecording,
    bool? userSpeaking,
    String? transcript,
    List<String>? inputTranscripts,
    String? emotion,
    String? emotionDetail,
    List<String>? coachingSuggestions,
    String? direction,
    String? technique,
    List<String>? suggestions,
    String? sessionId,
    String? errorMessage,
  }) {
    return VoiceCoachState(
      status: status ?? this.status,
      isRecording: isRecording ?? this.isRecording,
      userSpeaking: userSpeaking ?? this.userSpeaking,
      transcript: transcript ?? this.transcript,
      inputTranscripts: inputTranscripts ?? this.inputTranscripts,
      emotion: emotion ?? this.emotion,
      emotionDetail: emotionDetail ?? this.emotionDetail,
      coachingSuggestions: coachingSuggestions ?? this.coachingSuggestions,
      direction: direction ?? this.direction,
      technique: technique ?? this.technique,
      suggestions: suggestions ?? this.suggestions,
      sessionId: sessionId ?? this.sessionId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 語音教練核心邏輯控制器
///
/// 負責 WebSocket 連線管理、音訊錄製串流、以及處理後端推送的各類事件。
class VoiceCoachNotifier extends StateNotifier<VoiceCoachState> {
  final VoiceCoachWs _ws = VoiceCoachWs();
  final PlatformAudioRecorder _recorder = createPlatformRecorder();
  StreamSubscription<Uint8List>? _audioSub;

  VoiceCoachNotifier() : super(const VoiceCoachState());

  /// 建立新的語音教練會話，連接 WebSocket 並重設所有狀態
  Future<void> startSession() async {
    final sessionId = const Uuid().v4();
    debugPrint('[VC] startSession: $sessionId');
    state = state.copyWith(
      status: VoiceCoachStatus.connecting,
      sessionId: sessionId,
      suggestions: [],
      transcript: '',
      inputTranscripts: [],
      emotion: '',
      emotionDetail: '',
      coachingSuggestions: [],
      direction: '',
      technique: '',
      errorMessage: null,
    );

    try {
      await _ws.connect(
        sessionId,
        onMessage: _handleMessage,
        onError: (e) {
          debugPrint('[VC] ws onError: $e');
          state = state.copyWith(
            status: VoiceCoachStatus.error,
            errorMessage: '連線失敗，請稍後再試',
          );
        },
        onDone: () {
          debugPrint('[VC] ws onDone');
          if (state.status != VoiceCoachStatus.disconnected) {
            state = state.copyWith(status: VoiceCoachStatus.disconnected);
          }
        },
      );
      debugPrint('[VC] ws connected OK');
    } catch (e) {
      debugPrint('[VC] ws connect error: $e');
      state = state.copyWith(
        status: VoiceCoachStatus.error,
        errorMessage: '無法連線語音教練，請檢查網路',
      );
    }
  }

  int _audioChunkCount = 0;

  /// 開始錄音，將 PCM16 音訊串流透過 WebSocket 傳送至後端
  Future<void> startRecording() async {
    debugPrint('[VC] startRecording called, status=${state.status}');
    if (state.status != VoiceCoachStatus.connected) {
      debugPrint('[VC] startRecording aborted: not connected');
      return;
    }

    try {
      final hasPermission = await _recorder.hasPermission();
      debugPrint('[VC] microphone permission: $hasPermission');
      if (!hasPermission) {
        state = state.copyWith(
          errorMessage: 'Microphone permission denied',
        );
        return;
      }
    } catch (e) {
      debugPrint('[VC] hasPermission error: $e');
      state = state.copyWith(
        errorMessage: 'Failed to check mic permission: $e',
      );
      return;
    }

    try {
      _audioChunkCount = 0;
      debugPrint('[VC] calling recorder.startStream...');
      final stream = await _recorder.startStream();
      debugPrint('[VC] recorder stream started OK');

      _audioSub = stream.listen(
        (bytes) {
          _audioChunkCount++;
          if (_audioChunkCount <= 3 || _audioChunkCount % 50 == 0) {
            debugPrint(
                '[VC] audio chunk #$_audioChunkCount, ${bytes.length} bytes');
          }
          final base64Audio = base64Encode(bytes);
          _ws.sendAudio(base64Audio);
        },
        onError: (e) {
          debugPrint('[VC] audio stream error: $e');
          state = state.copyWith(
            isRecording: false,
            errorMessage: 'Audio stream error: $e',
          );
        },
        onDone: () {
          debugPrint('[VC] audio stream done');
        },
      );

      state = state.copyWith(isRecording: true);
      debugPrint('[VC] recording started');
    } catch (e, st) {
      debugPrint('[VC] startStream error: $e');
      debugPrint('[VC] stackTrace: $st');
      state = state.copyWith(
        errorMessage: 'Failed to start recording: $e',
      );
    }
  }

  /// 停止錄音，取消音訊串流訂閱
  Future<void> stopRecording() async {
    await _audioSub?.cancel();
    _audioSub = null;
    await _recorder.stop();
    state = state.copyWith(isRecording: false);
  }

  /// 結束整個語音教練會話，清理所有資源
  Future<void> endSession() async {
    await stopRecording();
    if (_ws.isConnected) {
      _ws.sendClose();
      await _ws.disconnect();
    }
    state = const VoiceCoachState();
  }

  /// 處理後端 WebSocket 推送的各類訊息事件
  void _handleMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    // 音訊事件量太大不印
    if (type != 'audio') {
      debugPrint('[VC] onMessage: type=$type');
    }
    switch (type) {
      // 會話就緒，可以開始錄音
      case 'session_ready':
        debugPrint('[VC] session_ready received');
        state = state.copyWith(status: VoiceCoachStatus.connected);

      // AI 教練語音的即時轉寫（流式 delta）
      case 'transcript':
        final text = msg['payload'] as String? ?? '';
        state = state.copyWith(transcript: state.transcript + text);

      // AI 教練語音的完整轉寫（一個回應結束），重設 streaming transcript
      case 'transcript_done':
        state = state.copyWith(transcript: '');

      // 麥克風收音的語音辨識結果（完整句子）
      case 'input_transcript':
        final text = msg['payload'] as String? ?? '';
        if (text.isNotEmpty) {
          state = state.copyWith(
            inputTranscripts: [...state.inputTranscripts, text],
          );
        }

      // 結構化教練更新（包含情緒、建議、方向、技巧）
      case 'coaching_update':
        final payload = msg['payload'];
        if (payload is Map) {
          final emotion = payload['emotion'] as String? ?? '';
          final emotionDetail = payload['emotion_detail'] as String? ?? '';
          final direction = payload['direction'] as String? ?? '';
          final technique = payload['technique'] as String? ?? '';
          final rawSuggestions = payload['suggestions'];
          final suggestions = <String>[];
          if (rawSuggestions is List) {
            for (final s in rawSuggestions) {
              if (s is String && s.isNotEmpty) suggestions.add(s);
            }
          }
          state = state.copyWith(
            emotion: emotion,
            emotionDetail: emotionDetail,
            coachingSuggestions: suggestions,
            direction: direction,
            technique: technique,
          );
        }

      // 純文字建議（後備，當 JSON 解析失敗時由後端發送）
      case 'suggestion':
        final text = msg['payload'] as String? ?? '';
        if (text.isNotEmpty) {
          state = state.copyWith(
            suggestions: [...state.suggestions, text],
          );
        }

      // 使用者開始說話
      case 'speech_started':
        state = state.copyWith(userSpeaking: true);

      // 使用者停止說話
      case 'speech_stopped':
        state = state.copyWith(userSpeaking: false);

      // AI 回應完成
      case 'response_complete':
        break;

      // AI 語音回放（未來功能）
      case 'audio':
        break;

      // 錯誤事件
      case 'error':
        final payload = msg['payload'];
        final message = payload is Map
            ? payload['message'] ?? 'Unknown error'
            : 'Unknown error';
        state = state.copyWith(
          status: VoiceCoachStatus.error,
          errorMessage: message as String,
        );
    }
  }

  @override
  void dispose() {
    endSession();
    _recorder.dispose();
    super.dispose();
  }
}

/// 語音教練會話 Provider
final voiceCoachSessionProvider =
    StateNotifierProvider<VoiceCoachNotifier, VoiceCoachState>((ref) {
  return VoiceCoachNotifier();
});

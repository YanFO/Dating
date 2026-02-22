// 跨平台錄音器介面
//
// 定義統一的錄音器介面，讓 voice_coach_provider 可以在 web 和 native 平台
// 使用不同的錄音實作，而不需要條件式匯入。

import 'dart:async';
import 'dart:typed_data';

/// 跨平台 PCM16 錄音器介面
abstract class PlatformAudioRecorder {
  /// 檢查是否有麥克風權限
  Future<bool> hasPermission();

  /// 開始錄音，回傳 PCM16 24kHz mono 音訊串流
  Future<Stream<Uint8List>> startStream();

  /// 停止錄音
  Future<void> stop();

  /// 釋放資源
  void dispose();
}

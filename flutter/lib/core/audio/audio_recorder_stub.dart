// 條件式匯入的預設存根（不應被直接使用）
import 'audio_recorder_interface.dart';

PlatformAudioRecorder createPlatformRecorder() =>
    throw UnsupportedError('Cannot create recorder without dart:io or dart:html');

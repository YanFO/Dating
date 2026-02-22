// Native 平台（Android/iOS）錄音實作
//
// 使用 record 套件的 AudioRecorder，直接支援 PCM16 24kHz 串流。

import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import 'audio_recorder_interface.dart';

class NativeAudioRecorder implements PlatformAudioRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> startStream() async {
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 24000,
      numChannels: 1,
    ));
    return stream;
  }

  @override
  Future<void> stop() => _recorder.stop();

  @override
  void dispose() => _recorder.dispose();
}

PlatformAudioRecorder createPlatformRecorder() => NativeAudioRecorder();

// Web 平台的原生 PCM16 錄音實作
//
// 使用 Web Audio API (AudioWorklet) 直接擷取麥克風音訊，
// 並透過 AudioWorklet 降頻至 24kHz PCM16 格式。
// 這比 record 套件更可靠，因為可以精確控制取樣率與位元深度。

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'audio_recorder_interface.dart';

class WebAudioRecorder implements PlatformAudioRecorder {
  web.AudioContext? _audioContext;
  web.MediaStream? _mediaStream;
  web.AudioWorkletNode? _workletNode;
  web.MediaStreamAudioSourceNode? _sourceNode;
  StreamController<Uint8List>? _controller;
  bool _isRecording = false;

  @override
  Future<bool> hasPermission() async {
    try {
      final constraints = web.MediaStreamConstraints(audio: true.toJS);
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;
      for (final track in stream.getAudioTracks().toDart) {
        track.stop();
      }
      return true;
    } catch (e) {
      debugPrint('[WebAudioRecorder] permission check failed: $e');
      return false;
    }
  }

  @override
  Future<Stream<Uint8List>> startStream() async {
    if (_isRecording) {
      throw StateError('Already recording');
    }

    debugPrint('[WebAudioRecorder] starting...');
    _controller = StreamController<Uint8List>();

    // 1. 取得麥克風串流
    final constraints = web.MediaStreamConstraints(audio: true.toJS);
    _mediaStream = await web.window.navigator.mediaDevices
        .getUserMedia(constraints)
        .toDart;
    debugPrint('[WebAudioRecorder] got media stream');

    // 2. 建立 AudioContext
    _audioContext = web.AudioContext();
    debugPrint(
        '[WebAudioRecorder] AudioContext sampleRate: ${_audioContext!.sampleRate}');

    // 3. 載入 AudioWorklet（addModule 接受 Dart String，不需 .toJS）
    await _audioContext!.audioWorklet
        .addModule('audio_pcm_worker.js')
        .toDart;
    debugPrint('[WebAudioRecorder] AudioWorklet loaded');

    // 4. 建立處理鏈
    _sourceNode = _audioContext!.createMediaStreamSource(_mediaStream!);
    _workletNode = web.AudioWorkletNode(_audioContext!, 'pcm16-processor');

    // 5. 接收 PCM16 資料
    _workletNode!.port.onmessage = (web.MessageEvent event) {
      final buffer = event.data as JSArrayBuffer;
      final bytes = Uint8List.view(buffer.toDart);
      if (_controller != null && !_controller!.isClosed && bytes.isNotEmpty) {
        _controller!.add(bytes);
      }
    }.toJS;

    // 6. 連接音訊處理鏈
    _sourceNode!.connect(_workletNode!);

    _isRecording = true;
    debugPrint('[WebAudioRecorder] recording started');

    return _controller!.stream;
  }

  @override
  Future<void> stop() async {
    debugPrint('[WebAudioRecorder] stopping...');
    _isRecording = false;

    _sourceNode?.disconnect();
    _workletNode?.disconnect();
    _sourceNode = null;
    _workletNode = null;

    if (_mediaStream != null) {
      for (final track in _mediaStream!.getAudioTracks().toDart) {
        track.stop();
      }
      _mediaStream = null;
    }

    if (_audioContext != null && _audioContext!.state != 'closed') {
      await _audioContext!.close().toDart;
      _audioContext = null;
    }

    debugPrint('[WebAudioRecorder] stopped');
  }

  @override
  void dispose() {
    stop();
    if (_controller != null && !_controller!.isClosed) {
      _controller!.close();
    }
    _controller = null;
  }
}

PlatformAudioRecorder createPlatformRecorder() => WebAudioRecorder();

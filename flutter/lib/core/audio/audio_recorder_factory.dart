// 跨平台錄音器工廠
//
// 使用 Dart 條件式匯入，在 web 平台使用 WebAudioRecorder，
// 在 native 平台使用 record 套件的 AudioRecorder。

export 'audio_recorder_interface.dart';
export 'audio_recorder_stub.dart'
    if (dart.library.js_interop) 'web_audio_recorder.dart'
    if (dart.library.io) 'audio_recorder_native.dart';

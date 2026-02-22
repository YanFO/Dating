import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../constants/api_endpoints.dart';

class VoiceCoachWs {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  bool get isConnected => _channel != null;

  Future<void> connect(
    String sessionId, {
    required void Function(Map<String, dynamic>) onMessage,
    required void Function(dynamic) onError,
    required void Function() onDone,
  }) async {
    final wsUrl = ApiEndpoints.voiceCoachWs(sessionId);
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    await _channel!.ready;
    _subscription = _channel!.stream.listen(
      (data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;
        onMessage(msg);
      },
      onError: onError,
      onDone: onDone,
    );
  }

  void sendAudio(String base64Audio) {
    _channel?.sink.add(jsonEncode({'type': 'audio', 'payload': base64Audio}));
  }

  void sendClose() {
    _channel?.sink.add(jsonEncode({'type': 'close'}));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;

abstract final class ApiEndpoints {
  /// Same-origin: Flutter Web is served by the backend on the same port,
  /// so all API calls are relative to the page origin. No CORS needed.
  static String get baseUrl {
    if (kIsWeb) {
      return Uri.base.origin; // e.g. http://localhost:8000
    }
    return 'http://localhost:9999';
  }

  static const String apiPrefix = '/api';

  // Health
  static const String health = '$apiPrefix/health';

  // Icebreaker endpoints
  static const String icebreaker = '$apiPrefix/icebreaker';
  static const String icebreakerAnalyze = '$icebreaker/analyze';

  // Reply coach endpoints
  static const String reply = '$apiPrefix/reply';
  static const String replyAnalyze = '$reply/analyze';

  // Voice coach endpoints
  static const String voiceCoach = '$apiPrefix/voice-coach';

  // Job status
  static const String jobs = '$apiPrefix/jobs';
  static String jobById(String id) => '$jobs/$id';

  // Match pipeline endpoints
  static const String matches = '$apiPrefix/matches';
  static String matchById(String id) => '$matches/$id';

  // Persona endpoints
  static const String persona = '$apiPrefix/persona';
  static const String personaTone = '$persona/tone';
  static const String personaSandbox = '$persona/sandbox';

  // Love Coach endpoints
  static const String loveCoach = '$apiPrefix/love-coach';
  static const String loveCoachChat = '$loveCoach/chat';
  static const String loveCoachConversations = '$loveCoach/conversations';

  // Insights endpoints
  static const String insightsSkills = '$apiPrefix/insights/skills';
  static const String insightsReports = '$apiPrefix/insights/reports';
  static const String insightsVoiceCoachLogs =
      '$apiPrefix/insights/voice-coach-logs';

  // WebSocket endpoints
  static String voiceCoachWs(String sessionId) {
    final wsBase = baseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    return '$wsBase/ws/voice-coach/$sessionId';
  }
}

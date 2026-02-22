class SkillScores {
  final double emotionalValue;
  final double listening;
  final double frameControl;
  final double escalation;
  final double empathy;
  final double humor;

  const SkillScores({
    this.emotionalValue = 0.0,
    this.listening = 0.0,
    this.frameControl = 0.0,
    this.escalation = 0.0,
    this.empathy = 0.0,
    this.humor = 0.0,
  });

  List<double> toList() => [
        emotionalValue,
        listening,
        frameControl,
        escalation,
        empathy,
        humor,
      ];

  factory SkillScores.fromJson(Map<String, dynamic> json) {
    return SkillScores(
      emotionalValue: (json['emotional_value'] as num?)?.toDouble() ?? 0.0,
      listening: (json['listening'] as num?)?.toDouble() ?? 0.0,
      frameControl: (json['frame_control'] as num?)?.toDouble() ?? 0.0,
      escalation: (json['escalation'] as num?)?.toDouble() ?? 0.0,
      empathy: (json['empathy'] as num?)?.toDouble() ?? 0.0,
      humor: (json['humor'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DateReport {
  final String reportId;
  final int score;
  final SkillScores skills;
  final List<String> goodPoints;
  final List<String> toImprove;
  final List<String> actionItems;
  final String createdAt;

  const DateReport({
    required this.reportId,
    this.score = 0,
    this.skills = const SkillScores(),
    this.goodPoints = const [],
    this.toImprove = const [],
    this.actionItems = const [],
    this.createdAt = '',
  });

  factory DateReport.fromJson(Map<String, dynamic> json) {
    return DateReport(
      reportId: json['report_id'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      skills: json['skills'] != null
          ? SkillScores.fromJson(json['skills'] as Map<String, dynamic>)
          : const SkillScores(),
      goodPoints: (json['good_points'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      toImprove: (json['to_improve'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      actionItems: (json['action_items'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

/// 教練分析更新（情緒、建議、方向、技巧）
class CoachingUpdate {
  final String emotion;
  final String emotionDetail;
  final List<String> suggestions;
  final String direction;
  final String technique;

  const CoachingUpdate({
    this.emotion = '',
    this.emotionDetail = '',
    this.suggestions = const [],
    this.direction = '',
    this.technique = '',
  });

  factory CoachingUpdate.fromJson(Map<String, dynamic> json) {
    return CoachingUpdate(
      emotion: json['emotion'] as String? ?? '',
      emotionDetail: json['emotion_detail'] as String? ?? '',
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      direction: json['direction'] as String? ?? '',
      technique: json['technique'] as String? ?? '',
    );
  }
}

/// 語音教練對話紀錄
class VoiceCoachLog {
  final String logId;
  final String sessionId;
  final List<String> inputTranscripts;
  final List<String> coachTranscripts;
  final List<CoachingUpdate> coachingUpdates;
  final int durationMs;
  final String createdAt;

  const VoiceCoachLog({
    required this.logId,
    this.sessionId = '',
    this.inputTranscripts = const [],
    this.coachTranscripts = const [],
    this.coachingUpdates = const [],
    this.durationMs = 0,
    this.createdAt = '',
  });

  /// 格式化持續時間為 mm:ss
  String get durationFormatted {
    final totalSeconds = durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory VoiceCoachLog.fromJson(Map<String, dynamic> json) {
    return VoiceCoachLog(
      logId: json['log_id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      inputTranscripts: (json['input_transcripts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      coachTranscripts: (json['coach_transcripts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      coachingUpdates: (json['coaching_updates'] as List<dynamic>?)
              ?.map((e) =>
                  CoachingUpdate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      durationMs: json['duration_ms'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

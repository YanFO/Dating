class EmotionAnalysis {
  final String detectedEmotion;
  final String subtext;
  final double confidence;

  const EmotionAnalysis({
    required this.detectedEmotion,
    required this.subtext,
    this.confidence = 0.0,
  });

  factory EmotionAnalysis.fromJson(Map<String, dynamic> json) {
    return EmotionAnalysis(
      detectedEmotion: json['detected_emotion'] as String? ?? '',
      subtext: json['subtext'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReplyOption {
  final String text;
  final String intent;
  final String strategy;
  final String frameworkTechnique;

  const ReplyOption({
    required this.text,
    required this.intent,
    required this.strategy,
    this.frameworkTechnique = '',
  });

  factory ReplyOption.fromJson(Map<String, dynamic> json) {
    return ReplyOption(
      text: json['text'] as String? ?? '',
      intent: json['intent'] as String? ?? '',
      strategy: json['strategy'] as String? ?? '',
      frameworkTechnique: json['framework_technique'] as String? ?? '',
    );
  }
}

class CoachPanel {
  final String perspectiveNote;
  final List<String> dos;
  final List<String> donts;

  const CoachPanel({
    required this.perspectiveNote,
    this.dos = const [],
    this.donts = const [],
  });

  factory CoachPanel.fromJson(Map<String, dynamic> json) {
    return CoachPanel(
      perspectiveNote: json['perspective_note'] as String? ?? '',
      dos: (json['dos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      donts:
          (json['donts'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
    );
  }
}

class StageCoaching {
  final String currentStage;
  final String stageStrategy;
  final String techniqueUsed;
  final List<String> stageWarnings;

  const StageCoaching({
    required this.currentStage,
    required this.stageStrategy,
    required this.techniqueUsed,
    this.stageWarnings = const [],
  });

  factory StageCoaching.fromJson(Map<String, dynamic> json) {
    return StageCoaching(
      currentStage: json['current_stage'] as String? ?? '',
      stageStrategy: json['stage_strategy'] as String? ?? '',
      techniqueUsed: json['technique_used'] as String? ?? '',
      stageWarnings: (json['stage_warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class ReplyResult {
  final EmotionAnalysis emotionAnalysis;
  final List<ReplyOption> replyOptions;
  final CoachPanel? coachPanel;
  final StageCoaching? stageCoaching;

  const ReplyResult({
    required this.emotionAnalysis,
    this.replyOptions = const [],
    this.coachPanel,
    this.stageCoaching,
  });

  factory ReplyResult.fromJson(Map<String, dynamic> json) {
    return ReplyResult(
      emotionAnalysis: EmotionAnalysis.fromJson(
          json['emotion_analysis'] as Map<String, dynamic>? ?? {}),
      replyOptions: (json['reply_options'] as List<dynamic>?)
              ?.map((e) => ReplyOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      coachPanel: json['coach_panel'] != null
          ? CoachPanel.fromJson(json['coach_panel'] as Map<String, dynamic>)
          : null,
      stageCoaching: json['stage_coaching'] != null
          ? StageCoaching.fromJson(
              json['stage_coaching'] as Map<String, dynamic>)
          : null,
    );
  }
}

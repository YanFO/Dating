class ObservationHook {
  final String detail;
  final String hookType;

  const ObservationHook({required this.detail, required this.hookType});

  factory ObservationHook.fromJson(Map<String, dynamic> json) {
    return ObservationHook(
      detail: json['detail'] as String? ?? '',
      hookType: json['hook_type'] as String? ?? '',
    );
  }
}

class OpeningLine {
  final String text;
  final String tone;
  final double confidence;
  final String basedOn;

  const OpeningLine({
    required this.text,
    required this.tone,
    this.confidence = 0.0,
    this.basedOn = '',
  });

  factory OpeningLine.fromJson(Map<String, dynamic> json) {
    return OpeningLine(
      text: json['text'] as String? ?? '',
      tone: json['tone'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      basedOn: json['based_on'] as String? ?? '',
    );
  }
}

class TopicSuggestion {
  final String topic;
  final String context;

  const TopicSuggestion({required this.topic, required this.context});

  factory TopicSuggestion.fromJson(Map<String, dynamic> json) {
    return TopicSuggestion(
      topic: json['topic'] as String? ?? '',
      context: json['context'] as String? ?? '',
    );
  }
}

class IcebreakerResult {
  final String sceneAnalysis;
  final String approachReadiness;
  final List<ObservationHook> observationHooks;
  final List<OpeningLine> openingLines;
  final List<TopicSuggestion> topicSuggestions;
  final List<String> behaviorTips;

  const IcebreakerResult({
    required this.sceneAnalysis,
    this.approachReadiness = '',
    this.observationHooks = const [],
    this.openingLines = const [],
    this.topicSuggestions = const [],
    this.behaviorTips = const [],
  });

  factory IcebreakerResult.fromJson(Map<String, dynamic> json) {
    return IcebreakerResult(
      sceneAnalysis: json['scene_analysis'] as String? ?? '',
      approachReadiness: json['approach_readiness'] as String? ?? '',
      observationHooks: (json['observation_hooks'] as List<dynamic>?)
              ?.map((e) => ObservationHook.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      openingLines: (json['opening_lines'] as List<dynamic>?)
              ?.map((e) => OpeningLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topicSuggestions: (json['topic_suggestions'] as List<dynamic>?)
              ?.map((e) => TopicSuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      behaviorTips: (json['behavior_tips'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

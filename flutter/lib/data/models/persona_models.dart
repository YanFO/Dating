class PersonaSettings {
  final String userId;
  final double syncPct;
  final double emojiUsage;
  final double sentenceLength;
  final double colloquialism;

  const PersonaSettings({
    required this.userId,
    this.syncPct = 0.0,
    this.emojiUsage = 50.0,
    this.sentenceLength = 50.0,
    this.colloquialism = 50.0,
  });

  factory PersonaSettings.fromJson(Map<String, dynamic> json) {
    return PersonaSettings(
      userId: json['user_id'] as String? ?? '',
      syncPct: (json['sync_pct'] as num?)?.toDouble() ?? 0.0,
      emojiUsage: (json['emoji_usage'] as num?)?.toDouble() ?? 50.0,
      sentenceLength: (json['sentence_length'] as num?)?.toDouble() ?? 50.0,
      colloquialism: (json['colloquialism'] as num?)?.toDouble() ?? 50.0,
    );
  }
}

class SandboxResult {
  final String original;
  final String rewritten;

  const SandboxResult({required this.original, required this.rewritten});

  factory SandboxResult.fromJson(Map<String, dynamic> json) {
    return SandboxResult(
      original: json['original'] as String? ?? '',
      rewritten: json['rewritten'] as String? ?? '',
    );
  }
}

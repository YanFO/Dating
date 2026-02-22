class MatchRecord {
  final String matchId;
  final String name;
  final String? contextTag;
  final String status;
  final String createdAt;
  final String updatedAt;

  const MatchRecord({
    required this.matchId,
    required this.name,
    this.contextTag,
    this.status = 'active',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory MatchRecord.fromJson(Map<String, dynamic> json) {
    return MatchRecord(
      matchId: json['match_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contextTag: json['context_tag'] as String?,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

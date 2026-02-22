/// Love Coach 聊天資料模型
///
/// 定義聊天訊息與對話摘要的資料結構，
/// 用於前端狀態管理與後端 API 互動。

/// 單則聊天訊息
class LoveCoachMessage {
  /// 角色：'user' 或 'model'
  final String role;

  /// 訊息文字內容
  final String text;

  /// 訊息時間戳
  final DateTime timestamp;

  const LoveCoachMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  /// 是否為使用者訊息
  bool get isUser => role == 'user';

  /// 是否為 AI 模型回覆
  bool get isModel => role == 'model';

  /// 轉換為 JSON 格式（送入後端 history 陣列）
  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
      };

  /// 從後端 JSON 回應建立訊息物件
  factory LoveCoachMessage.fromJson(Map<String, dynamic> json) {
    return LoveCoachMessage(
      role: json['role'] as String,
      text: json['text'] as String,
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// 對話摘要（列表用）
class ConversationSummary {
  final String id;
  final String? title;
  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationSummary({
    required this.id,
    this.title,
    required this.messageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 從後端 JSON 回應建立摘要物件
  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'] as String,
      title: json['title'] as String?,
      messageCount: json['message_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

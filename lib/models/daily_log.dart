import 'package:uuid/uuid.dart';

enum LogEntryType { voice, vision, note, summary }

extension LogEntryTypeExtension on LogEntryType {
  String get value {
    switch (this) {
      case LogEntryType.voice:
        return 'voice';
      case LogEntryType.vision:
        return 'vision';
      case LogEntryType.note:
        return 'note';
      case LogEntryType.summary:
        return 'summary';
    }
  }

  static LogEntryType fromValue(String value) {
    return LogEntryType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => LogEntryType.note,
    );
  }
}

class DailyLog {
  final String id;
  final String userId;
  final String? conversationId;
  final DateTime logDate;
  final LogEntryType entryType;
  final String content;
  final DateTime createdAt;

  const DailyLog({
    required this.id,
    required this.userId,
    this.conversationId,
    required this.logDate,
    required this.entryType,
    required this.content,
    required this.createdAt,
  });

  factory DailyLog.create({
    required String userId,
    String? conversationId,
    required LogEntryType entryType,
    required String content,
  }) {
    final now = DateTime.now();
    return DailyLog(
      id: const Uuid().v4(),
      userId: userId,
      conversationId: conversationId,
      logDate: DateTime(now.year, now.month, now.day),
      entryType: entryType,
      content: content,
      createdAt: now,
    );
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      conversationId: map['conversation_id'] as String?,
      logDate: DateTime.parse(map['log_date'] as String),
      entryType: LogEntryTypeExtension.fromValue(map['entry_type'] as String),
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'conversation_id': conversationId,
      'log_date': logDate.toIso8601String().substring(0, 10),
      'entry_type': entryType.value,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

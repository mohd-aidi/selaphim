import 'package:uuid/uuid.dart';

class AlarmEntry {
  final String id;
  final String userId;
  final String title;
  final String? note;
  final DateTime scheduledAt;
  final bool isActive;
  final DateTime createdAt;

  const AlarmEntry({
    required this.id,
    required this.userId,
    required this.title,
    this.note,
    required this.scheduledAt,
    this.isActive = true,
    required this.createdAt,
  });

  factory AlarmEntry.create({
    required String userId,
    required String title,
    required DateTime scheduledAt,
    String? note,
  }) {
    final now = DateTime.now();
    return AlarmEntry(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      note: note,
      scheduledAt: scheduledAt,
      isActive: true,
      createdAt: now,
    );
  }

  factory AlarmEntry.fromMap(Map<String, dynamic> map) {
    return AlarmEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      note: map['note'] as String?,
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'note': note,
      'scheduled_at': scheduledAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AlarmEntry copyWith({bool? isActive, String? note}) {
    return AlarmEntry(
      id: id,
      userId: userId,
      title: title,
      note: note ?? this.note,
      scheduledAt: scheduledAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

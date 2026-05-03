import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant, system }

extension MessageRoleExtension on MessageRole {
  String get value {
    switch (this) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
    }
  }

  static MessageRole fromValue(String value) {
    return MessageRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => MessageRole.user,
    );
  }
}

enum ConversationMode { voice, vision, text }

extension ConversationModeExtension on ConversationMode {
  String get value {
    switch (this) {
      case ConversationMode.voice:
        return 'voice';
      case ConversationMode.vision:
        return 'vision';
      case ConversationMode.text:
        return 'text';
    }
  }

  static ConversationMode fromValue(String value) {
    return ConversationMode.values.firstWhere(
      (m) => m.value == value,
      orElse: () => ConversationMode.text,
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final String? imagePath;
  final int? tokensUsed;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.imagePath,
    this.tokensUsed,
    required this.createdAt,
  });

  factory Message.create({
    required String conversationId,
    required MessageRole role,
    required String content,
    String? imagePath,
    int? tokensUsed,
  }) {
    return Message(
      id: const Uuid().v4(),
      conversationId: conversationId,
      role: role,
      content: content,
      imagePath: imagePath,
      tokensUsed: tokensUsed,
      createdAt: DateTime.now(),
    );
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      role: MessageRoleExtension.fromValue(map['role'] as String),
      content: map['content'] as String,
      imagePath: map['image_path'] as String?,
      tokensUsed: map['tokens_used'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role.value,
      'content': content,
      'image_path': imagePath,
      'tokens_used': tokensUsed,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Conversation {
  final String id;
  final String userId;
  final String? title;
  final ConversationMode mode;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.userId,
    this.title,
    required this.mode,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.create({
    required String userId,
    required ConversationMode mode,
    String? title,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      mode: mode,
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Conversation.fromMap(Map<String, dynamic> map,
      {List<Message>? messages}) {
    return Conversation(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String?,
      mode: ConversationModeExtension.fromValue(map['mode'] as String),
      messages: messages ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'mode': mode.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? title,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id,
      userId: userId,
      title: title ?? this.title,
      mode: mode,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  List<Map<String, dynamic>> toApiMessages() {
    return messages
        .where((m) => m.role != MessageRole.system)
        .map((m) => {
              'role': m.role.value,
              'content': m.content,
            })
        .toList();
  }
}

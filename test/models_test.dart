import 'package:flutter_test/flutter_test.dart';

import 'package:selaphim/models/ai_provider.dart';
import 'package:selaphim/models/conversation.dart';
import 'package:selaphim/models/daily_log.dart';
import 'package:selaphim/models/user_profile.dart';
import 'package:selaphim/models/app_settings.dart';

void main() {
  group('AIProvider', () {
    test('fromValue returns correct provider', () {
      expect(AIProviderExtension.fromValue('openai'), AIProvider.openai);
      expect(AIProviderExtension.fromValue('gemini'), AIProvider.gemini);
      expect(AIProviderExtension.fromValue('claude'), AIProvider.claude);
    });

    test('fromValue defaults to openai for unknown value', () {
      expect(AIProviderExtension.fromValue('unknown'), AIProvider.openai);
    });

    test('availableModels is non-empty for all providers', () {
      for (final p in AIProvider.values) {
        expect(p.availableModels, isNotEmpty);
      }
    });

    test('supportsVision is true for all providers', () {
      for (final p in AIProvider.values) {
        expect(p.supportsVision, isTrue);
      }
    });

    test('defaultModel is first in availableModels', () {
      for (final p in AIProvider.values) {
        expect(p.defaultModel, p.availableModels.first);
      }
    });
  });

  group('UserProfile', () {
    test('create generates unique ids', () {
      final a = UserProfile.create(name: 'Alice');
      final b = UserProfile.create(name: 'Bob');
      expect(a.id, isNotEmpty);
      expect(a.id, isNot(b.id));
    });

    test('toMap / fromMap round-trip', () {
      final user = UserProfile.create(name: 'Test User');
      final map = user.toMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.id, user.id);
      expect(restored.name, user.name);
      expect(restored.avatarPath, user.avatarPath);
    });

    test('copyWith updates name and timestamp', () {
      final user = UserProfile.create(name: 'Alice');
      final updated = user.copyWith(name: 'Bob');

      expect(updated.id, user.id);
      expect(updated.name, 'Bob');
      expect(updated.updatedAt.isAfter(user.createdAt) ||
          updated.updatedAt == user.createdAt, isTrue);
    });
  });

  group('Message', () {
    test('create builds a valid message', () {
      final msg = Message.create(
        conversationId: 'conv-1',
        role: MessageRole.user,
        content: 'Hello',
      );

      expect(msg.id, isNotEmpty);
      expect(msg.conversationId, 'conv-1');
      expect(msg.role, MessageRole.user);
      expect(msg.content, 'Hello');
    });

    test('toMap / fromMap round-trip', () {
      final msg = Message.create(
        conversationId: 'conv-1',
        role: MessageRole.assistant,
        content: 'Hi there!',
        tokensUsed: 42,
      );

      final restored = Message.fromMap(msg.toMap());
      expect(restored.id, msg.id);
      expect(restored.role, msg.role);
      expect(restored.content, msg.content);
      expect(restored.tokensUsed, 42);
    });

    test('MessageRole.fromValue handles all roles', () {
      expect(
          MessageRoleExtension.fromValue('user'), MessageRole.user);
      expect(
          MessageRoleExtension.fromValue('assistant'), MessageRole.assistant);
      expect(
          MessageRoleExtension.fromValue('system'), MessageRole.system);
    });
  });

  group('Conversation', () {
    test('create sets correct defaults', () {
      final conv = Conversation.create(
        userId: 'user-1',
        mode: ConversationMode.voice,
      );

      expect(conv.id, isNotEmpty);
      expect(conv.userId, 'user-1');
      expect(conv.mode, ConversationMode.voice);
      expect(conv.messages, isEmpty);
    });

    test('toMap / fromMap round-trip', () {
      final conv = Conversation.create(
        userId: 'user-1',
        mode: ConversationMode.vision,
        title: 'Test Conv',
      );
      final restored = Conversation.fromMap(conv.toMap());

      expect(restored.id, conv.id);
      expect(restored.mode, conv.mode);
      expect(restored.title, 'Test Conv');
    });

    test('copyWith preserves id and userId', () {
      final conv = Conversation.create(
          userId: 'user-1', mode: ConversationMode.text);
      final updated = conv.copyWith(title: 'New Title');

      expect(updated.id, conv.id);
      expect(updated.userId, conv.userId);
      expect(updated.title, 'New Title');
    });

    test('toApiMessages excludes system messages', () {
      final conv = Conversation.create(
          userId: 'user-1', mode: ConversationMode.text);
      final systemMsg = Message.create(
          conversationId: conv.id,
          role: MessageRole.system,
          content: 'system prompt');
      final userMsg = Message.create(
          conversationId: conv.id,
          role: MessageRole.user,
          content: 'hello');
      final withMessages =
          conv.copyWith(messages: [systemMsg, userMsg]);

      final apiMessages = withMessages.toApiMessages();
      expect(apiMessages.length, 1);
      expect(apiMessages.first['role'], 'user');
    });
  });

  group('DailyLog', () {
    test('create sets log_date to today', () {
      final log = DailyLog.create(
        userId: 'user-1',
        entryType: LogEntryType.voice,
        content: 'test entry',
      );
      final today = DateTime.now();
      expect(log.logDate.year, today.year);
      expect(log.logDate.month, today.month);
      expect(log.logDate.day, today.day);
    });

    test('toMap / fromMap round-trip', () {
      final log = DailyLog.create(
        userId: 'user-1',
        entryType: LogEntryType.vision,
        content: 'I see a cat',
      );
      final restored = DailyLog.fromMap(log.toMap());

      expect(restored.id, log.id);
      expect(restored.entryType, log.entryType);
      expect(restored.content, log.content);
    });

    test('LogEntryType.fromValue defaults to note', () {
      expect(LogEntryTypeExtension.fromValue('unknown'),
          LogEntryType.note);
    });
  });

  group('AppSettings', () {
    test('defaults are sensible', () {
      final s = AppSettings.defaults(userId: 'user-1');

      expect(s.aiProvider, AIProvider.openai);
      expect(s.ttsSpeed, 1.0);
      expect(s.ttsPitch, 1.0);
      expect(s.liveVisionInterval, 10);
      expect(s.notificationsEnabled, isTrue);
    });

    test('toMap / fromMap round-trip', () {
      final s = AppSettings.defaults(userId: 'user-1');
      final restored = AppSettings.fromMap(s.toMap());

      expect(restored.id, s.id);
      expect(restored.aiProvider, s.aiProvider);
      expect(restored.aiModel, s.aiModel);
      expect(restored.ttsSpeed, s.ttsSpeed);
    });

    test('copyWith changes only specified fields', () {
      final s = AppSettings.defaults(userId: 'user-1');
      final updated = s.copyWith(ttsSpeed: 1.5);

      expect(updated.ttsSpeed, 1.5);
      expect(updated.ttsPitch, s.ttsPitch); // unchanged
      expect(updated.aiProvider, s.aiProvider); // unchanged
    });
  });
}

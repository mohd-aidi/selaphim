import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/conversation.dart';
import '../models/daily_log.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/secure_storage_service.dart';
import '../models/ai_provider.dart';

enum ConversationStatus { idle, loading, error, speaking }

class ConversationProvider extends ChangeNotifier {
  Conversation? _current;
  ConversationStatus _status = ConversationStatus.idle;
  String? _errorMessage;
  String? _currentUserId;

  Conversation? get current => _current;
  ConversationStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ConversationStatus.loading;

  void setUserId(String userId) {
    _currentUserId = userId;
  }

  void startNewConversation({
    required ConversationMode mode,
    required String userId,
  }) {
    _current = Conversation.create(userId: userId, mode: mode);
    _currentUserId = userId;
    _status = ConversationStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<String?> sendMessage({
    required String userMessage,
    required AIProvider provider,
    required String model,
    String? systemPrompt,
  }) async {
    if (_currentUserId == null) return null;

    // Ensure we have a conversation
    if (_current == null) {
      startNewConversation(
        mode: ConversationMode.text,
        userId: _currentUserId!,
      );
    }

    _status = ConversationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // Add user message optimistically
    final userMsg = Message.create(
      conversationId: _current!.id,
      role: MessageRole.user,
      content: userMessage,
    );
    _current = _current!.copyWith(
      messages: [..._current!.messages, userMsg],
    );
    notifyListeners();

    try {
      final apiKey =
          await SecureStorageService.instance.getApiKey(provider.value);
      if (apiKey == null || apiKey.isEmpty) {
        throw const AIServiceException(
            'No API key configured for this provider. Please add one in Settings.');
      }

      final service = buildAIService(
        provider: provider,
        apiKey: apiKey,
        model: model,
      );

      final reply = await service.chat(
        history: _current!.messages,
        userMessage: userMessage,
        systemPrompt: systemPrompt ??
            'You are Selaphim, a helpful AI assistant for daily life. '
                'Be concise, friendly and supportive.',
      );

      final assistantMsg = Message.create(
        conversationId: _current!.id,
        role: MessageRole.assistant,
        content: reply,
      );
      _current = _current!.copyWith(
        messages: [..._current!.messages, assistantMsg],
        title: _current!.title ?? _truncate(userMessage, 40),
      );
      _status = ConversationStatus.idle;
      notifyListeners();

      // Persist
      await _persist(userMsg, assistantMsg, userMessage, reply);

      return reply;
    } on AIServiceException catch (e) {
      _errorMessage = e.message;
      _status = ConversationStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ConversationStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<String?> analyseImage({
    required Uint8List imageBytes,
    required String prompt,
    required AIProvider provider,
    required String model,
  }) async {
    if (_currentUserId == null) return null;

    if (_current == null || _current!.mode != ConversationMode.vision) {
      startNewConversation(
        mode: ConversationMode.vision,
        userId: _currentUserId!,
      );
    }

    _status = ConversationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final userMsg = Message.create(
      conversationId: _current!.id,
      role: MessageRole.user,
      content: prompt,
    );
    _current = _current!.copyWith(
      messages: [..._current!.messages, userMsg],
    );
    notifyListeners();

    try {
      final apiKey =
          await SecureStorageService.instance.getApiKey(provider.value);
      if (apiKey == null || apiKey.isEmpty) {
        throw const AIServiceException(
            'No API key configured. Please add one in Settings.');
      }

      final service = buildAIService(
        provider: provider,
        apiKey: apiKey,
        model: model,
      );

      final reply = await service.analyseImage(
        imageBytes: imageBytes,
        prompt: prompt,
      );

      final assistantMsg = Message.create(
        conversationId: _current!.id,
        role: MessageRole.assistant,
        content: reply,
      );
      _current = _current!.copyWith(
        messages: [..._current!.messages, assistantMsg],
        title: _current!.title ?? 'Vision: ${_truncate(reply, 40)}',
      );
      _status = ConversationStatus.idle;
      notifyListeners();

      await _persist(userMsg, assistantMsg, prompt, reply,
          entryType: LogEntryType.vision);
      return reply;
    } on AIServiceException catch (e) {
      _errorMessage = e.message;
      _status = ConversationStatus.error;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ConversationStatus.error;
      notifyListeners();
      return null;
    }
  }

  Future<void> _persist(
    Message userMsg,
    Message assistantMsg,
    String userContent,
    String assistantContent, {
    LogEntryType entryType = LogEntryType.voice,
  }) async {
    final db = DatabaseService.instance;
    await db.upsertConversation(_current!);
    await db.insertMessage(userMsg);
    await db.insertMessage(assistantMsg);

    final log = DailyLog.create(
      userId: _currentUserId!,
      conversationId: _current!.id,
      entryType: entryType,
      content: 'Q: $userContent\nA: $assistantContent',
    );
    await db.insertLog(log);
  }

  void clearError() {
    _errorMessage = null;
    _status = ConversationStatus.idle;
    notifyListeners();
  }

  static String _truncate(String s, int maxLen) =>
      s.length <= maxLen ? s : '${s.substring(0, maxLen)}…';
}

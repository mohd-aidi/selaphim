import 'package:flutter/foundation.dart';

import '../models/conversation.dart';
import '../models/daily_log.dart';
import '../services/database_service.dart';

class ActivityProvider extends ChangeNotifier {
  List<DailyLog> _todaysLogs = [];
  List<Conversation> _conversations = [];
  Map<String, int> _stats = {};
  bool _loading = false;

  List<DailyLog> get todaysLogs => _todaysLogs;
  List<Conversation> get conversations => _conversations;
  Map<String, int> get stats => _stats;
  bool get loading => _loading;

  int get totalToday => _todaysLogs.length;
  int get voiceCount =>
      _todaysLogs.where((l) => l.entryType == LogEntryType.voice).length;
  int get visionCount =>
      _todaysLogs.where((l) => l.entryType == LogEntryType.vision).length;
  int get noteCount =>
      _todaysLogs.where((l) => l.entryType == LogEntryType.note).length;

  Future<void> loadForUser(String userId) async {
    _loading = true;
    notifyListeners();

    final db = DatabaseService.instance;
    _todaysLogs = await db.getLogsForDate(userId, DateTime.now());
    _conversations = await db.getConversations(userId, limit: 30);
    _stats = await db.getDailyStats(userId);

    _loading = false;
    notifyListeners();
  }

  Future<void> addNote({
    required String userId,
    required String content,
  }) async {
    final log = DailyLog.create(
      userId: userId,
      entryType: LogEntryType.note,
      content: content,
    );
    await DatabaseService.instance.insertLog(log);
    _todaysLogs = [log, ..._todaysLogs];
    notifyListeners();
  }

  Future<void> deleteLog(String logId) async {
    await DatabaseService.instance.deleteLog(logId);
    _todaysLogs.removeWhere((l) => l.id == logId);
    notifyListeners();
  }

  Future<void> deleteConversation(String convId, String userId) async {
    await DatabaseService.instance.deleteConversation(convId);
    _conversations.removeWhere((c) => c.id == convId);
    notifyListeners();
  }

  Future<void> deleteAllHistory(String userId) async {
    final db = DatabaseService.instance;
    await db.deleteAllLogs(userId);
    await db.deleteAllConversations(userId);
    _todaysLogs = [];
    _conversations = [];
    _stats = {};
    notifyListeners();
  }

  Future<List<Conversation>> searchConversations(
      String userId, String query) async {
    final all = await DatabaseService.instance.getConversations(userId, limit: 200);
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all
        .where((c) =>
            (c.title?.toLowerCase().contains(q) ?? false) ||
            c.messages.any((m) => m.content.toLowerCase().contains(q)))
        .toList();
  }

  Future<String> exportHistory(String userId) async {
    final all =
        await DatabaseService.instance.getConversations(userId, limit: 500);
    final buffer = StringBuffer();
    for (final conv in all) {
      buffer.writeln('=== ${conv.title ?? conv.id} (${conv.mode.value}) ===');
      buffer.writeln('Created: ${conv.createdAt.toIso8601String()}');
      for (final msg in conv.messages) {
        buffer.writeln('[${msg.role.value.toUpperCase()}] ${msg.content}');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}

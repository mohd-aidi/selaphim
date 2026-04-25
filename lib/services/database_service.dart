import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/conversation.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import '../models/app_settings.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _openDb();
    return _db!;
  }

  Future<void> init() async {
    _db = await _openDb();
  }

  Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'selaphim.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id           TEXT PRIMARY KEY,
        name         TEXT NOT NULL,
        avatar_path  TEXT,
        created_at   TEXT NOT NULL,
        updated_at   TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id                    TEXT PRIMARY KEY,
        user_id               TEXT NOT NULL UNIQUE,
        ai_provider           TEXT NOT NULL DEFAULT 'openai',
        ai_model              TEXT NOT NULL DEFAULT 'gpt-4o',
        tts_voice             TEXT,
        tts_speed             REAL NOT NULL DEFAULT 1.0,
        tts_pitch             REAL NOT NULL DEFAULT 1.0,
        language_code         TEXT NOT NULL DEFAULT 'en-US',
        theme                 TEXT NOT NULL DEFAULT 'system',
        live_vision_interval  INTEGER NOT NULL DEFAULT 10,
        notifications_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        id         TEXT PRIMARY KEY,
        user_id    TEXT NOT NULL,
        title      TEXT,
        mode       TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id              TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role            TEXT NOT NULL,
        content         TEXT NOT NULL,
        image_path      TEXT,
        tokens_used     INTEGER,
        created_at      TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_logs (
        id              TEXT PRIMARY KEY,
        user_id         TEXT NOT NULL,
        conversation_id TEXT,
        log_date        TEXT NOT NULL,
        entry_type      TEXT NOT NULL,
        content         TEXT NOT NULL,
        created_at      TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE SET NULL
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_conv_user ON conversations(user_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_msg_conv ON messages(conversation_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_log_user_date ON daily_logs(user_id, log_date)');
  }

  // ─── Users ─────────────────────────────────────────────────────────────────

  Future<void> upsertUser(UserProfile user) async {
    final db = await database;
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserProfile?> getUser(String id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<List<UserProfile>> getAllUsers() async {
    final db = await database;
    final rows = await db.query('users');
    return rows.map(UserProfile.fromMap).toList();
  }

  // ─── Settings ──────────────────────────────────────────────────────────────

  Future<void> upsertSettings(AppSettings settings) async {
    final db = await database;
    await db.insert('settings', settings.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AppSettings?> getSettings(String userId) async {
    final db = await database;
    final rows =
        await db.query('settings', where: 'user_id = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;
    return AppSettings.fromMap(rows.first);
  }

  // ─── Conversations ─────────────────────────────────────────────────────────

  Future<void> upsertConversation(Conversation conv) async {
    final db = await database;
    await db.insert('conversations', conv.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Conversation>> getConversations(String userId,
      {int limit = 50, int offset = 0}) async {
    final db = await database;
    final rows = await db.query(
      'conversations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );
    final conversations = <Conversation>[];
    for (final row in rows) {
      final messages = await getMessages(row['id'] as String);
      conversations.add(Conversation.fromMap(row, messages: messages));
    }
    return conversations;
  }

  Future<Conversation?> getConversation(String id) async {
    final db = await database;
    final rows =
        await db.query('conversations', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final messages = await getMessages(id);
    return Conversation.fromMap(rows.first, messages: messages);
  }

  Future<void> deleteConversation(String id) async {
    final db = await database;
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllConversations(String userId) async {
    final db = await database;
    await db
        .delete('conversations', where: 'user_id = ?', whereArgs: [userId]);
  }

  // ─── Messages ──────────────────────────────────────────────────────────────

  Future<void> insertMessage(Message message) async {
    final db = await database;
    await db.insert('messages', message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
    return rows.map(Message.fromMap).toList();
  }

  // ─── Daily Logs ────────────────────────────────────────────────────────────

  Future<void> insertLog(DailyLog log) async {
    final db = await database;
    await db.insert('daily_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DailyLog>> getLogsForDate(
      String userId, DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await db.query(
      'daily_logs',
      where: 'user_id = ? AND log_date = ?',
      whereArgs: [userId, dateStr],
      orderBy: 'created_at ASC',
    );
    return rows.map(DailyLog.fromMap).toList();
  }

  Future<List<DailyLog>> getLogsByDateRange(
      String userId, DateTime from, DateTime to) async {
    final db = await database;
    final fromStr = from.toIso8601String().substring(0, 10);
    final toStr = to.toIso8601String().substring(0, 10);
    final rows = await db.query(
      'daily_logs',
      where: 'user_id = ? AND log_date >= ? AND log_date <= ?',
      whereArgs: [userId, fromStr, toStr],
      orderBy: 'created_at DESC',
    );
    return rows.map(DailyLog.fromMap).toList();
  }

  Future<void> deleteLog(String id) async {
    final db = await database;
    await db.delete('daily_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllLogs(String userId) async {
    final db = await database;
    await db.delete('daily_logs', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<Map<String, int>> getDailyStats(String userId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT entry_type, COUNT(*) as count
      FROM daily_logs
      WHERE user_id = ?
      GROUP BY entry_type
    ''', [userId]);
    return {for (final r in rows) r['entry_type'] as String: r['count'] as int};
  }
}

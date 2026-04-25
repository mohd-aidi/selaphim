import '../models/alarm_entry.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/// Manages alarms: persists them in sqflite and fires notifications.
class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  /// Set a new alarm. Persists to DB and schedules a local notification.
  Future<AlarmEntry> setAlarm({
    required String userId,
    required String title,
    required DateTime scheduledAt,
    String? note,
  }) async {
    final alarm = AlarmEntry.create(
      userId: userId,
      title: title,
      scheduledAt: scheduledAt,
      note: note,
    );
    await DatabaseService.instance.upsertAlarm(alarm);

    // Use a stable int id derived from the UUID for the notification
    final notifId = alarm.id.hashCode.abs() % 100000;

    await NotificationService.instance.schedule(
      id: notifId,
      title: '⏰ $title',
      body: note ?? 'Alarm set by your AI assistant',
      scheduledAt: scheduledAt,
    );

    return alarm;
  }

  /// Cancel and delete an alarm.
  Future<void> cancelAlarm(AlarmEntry alarm) async {
    final notifId = alarm.id.hashCode.abs() % 100000;
    await NotificationService.instance.cancel(notifId);
    await DatabaseService.instance.deactivateAlarm(alarm.id);
  }

  /// Delete an alarm permanently.
  Future<void> deleteAlarm(String alarmId) async {
    await DatabaseService.instance.deleteAlarm(alarmId);
  }

  /// Get all upcoming (active) alarms for a user.
  Future<List<AlarmEntry>> getUpcomingAlarms(String userId) async {
    final alarms =
        await DatabaseService.instance.getAlarms(userId, activeOnly: true);
    final now = DateTime.now();
    return alarms.where((a) => a.scheduledAt.isAfter(now)).toList();
  }

  /// Get all alarms (active + past) for a user.
  Future<List<AlarmEntry>> getAllAlarms(String userId) async {
    return DatabaseService.instance.getAlarms(userId);
  }
}

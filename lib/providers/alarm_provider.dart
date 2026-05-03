import 'package:flutter/foundation.dart';

import '../models/alarm_entry.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';

class AlarmProvider extends ChangeNotifier {
  List<AlarmEntry> _alarms = [];
  bool _loading = false;

  List<AlarmEntry> get alarms => _alarms;
  bool get loading => _loading;

  List<AlarmEntry> get upcomingAlarms {
    final now = DateTime.now();
    return _alarms
        .where((a) => a.isActive && a.scheduledAt.isAfter(now))
        .toList();
  }

  Future<void> loadForUser(String userId) async {
    _loading = true;
    notifyListeners();
    _alarms = await AlarmService.instance.getAllAlarms(userId);
    _loading = false;
    notifyListeners();
  }

  Future<AlarmEntry> addAlarm({
    required String userId,
    required String title,
    required DateTime scheduledAt,
    String? note,
  }) async {
    final alarm = await AlarmService.instance.setAlarm(
      userId: userId,
      title: title,
      scheduledAt: scheduledAt,
      note: note,
    );
    _alarms = [alarm, ..._alarms];
    notifyListeners();
    return alarm;
  }

  Future<void> cancelAlarm(AlarmEntry alarm) async {
    await AlarmService.instance.cancelAlarm(alarm);
    final idx = _alarms.indexWhere((a) => a.id == alarm.id);
    if (idx >= 0) {
      _alarms[idx] = alarm.copyWith(isActive: false);
    }
    notifyListeners();
  }

  Future<void> deleteAlarm(AlarmEntry alarm) async {
    await AlarmService.instance.deleteAlarm(alarm.id);
    _alarms.removeWhere((a) => a.id == alarm.id);
    notifyListeners();
  }

  /// Send an immediate notification (used by the AI as a tool).
  Future<void> sendNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await NotificationService.instance.show(id: id, title: title, body: body);
  }
}

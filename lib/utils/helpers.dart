import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  static String formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  static String formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('MMM d, HH:mm').format(dt);
  }

  static String truncate(String s, int maxLen) =>
      s.length <= maxLen ? s : '${s.substring(0, maxLen)}…';
}

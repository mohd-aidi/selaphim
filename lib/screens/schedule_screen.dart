import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/alarm_entry.dart';
import '../providers/alarm_provider.dart';
import '../providers/settings_provider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<SettingsProvider>().user?.id;
    if (userId == null) return;
    await context.read<AlarmProvider>().loadForUser(userId);
  }

  Future<void> _addAlarm() async {
    final settings = context.read<SettingsProvider>();
    final userId = settings.user?.id;
    if (userId == null) return;

    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime? picked;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDlgState) => AlertDialog(
          title: const Text('Set Alarm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Note (optional)'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(picked == null
                      ? 'Pick date & time'
                      : DateFormat('dd MMM yyyy HH:mm').format(picked!)),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: ctx2,
                      initialDate: DateTime.now().add(const Duration(hours: 1)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null || !ctx2.mounted) return;
                    final time = await showTimePicker(
                      context: ctx2,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time == null) return;
                    setDlgState(() {
                      picked = DateTime(date.year, date.month, date.day,
                          time.hour, time.minute);
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: picked == null || titleCtrl.text.trim().isEmpty
                  ? null
                  : () async {
                      final alarmProv = context.read<AlarmProvider>();
                      await alarmProv.addAlarm(
                            userId: userId,
                            title: titleCtrl.text.trim(),
                            scheduledAt: picked!,
                            note: noteCtrl.text.trim().isEmpty
                                ? null
                                : noteCtrl.text.trim(),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alarmProvider = context.watch<AlarmProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule & Alarms')),
      body: alarmProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : alarmProvider.alarms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alarm_off_rounded,
                          size: 64, color: colorScheme.outlineVariant),
                      const SizedBox(height: 12),
                      const Text('No alarms set.\nTap + to add one.'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: alarmProvider.alarms.length,
                  itemBuilder: (ctx, i) {
                    final alarm = alarmProvider.alarms[i];
                    final isPast =
                        alarm.scheduledAt.isBefore(DateTime.now());
                    return ListTile(
                      leading: Icon(
                        alarm.isActive && !isPast
                            ? Icons.alarm_rounded
                            : Icons.alarm_off_rounded,
                        color: alarm.isActive && !isPast
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                      title: Text(alarm.title),
                      subtitle: Text(fmt.format(alarm.scheduledAt)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (alarm.isActive && !isPast)
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined),
                              tooltip: 'Cancel alarm',
                              onPressed: () =>
                                  alarmProvider.cancelAlarm(alarm),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: 'Delete',
                            onPressed: () => _confirmDelete(alarm),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        tooltip: 'Add alarm',
        child: const Icon(Icons.add_alarm_rounded),
      ),
    );
  }

  Future<void> _confirmDelete(AlarmEntry alarm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: Text('Delete "${alarm.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AlarmProvider>().deleteAlarm(alarm);
    }
  }
}

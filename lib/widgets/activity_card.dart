import 'package:flutter/material.dart';

import '../models/daily_log.dart';
import '../utils/helpers.dart';

class ActivityCard extends StatelessWidget {
  final DailyLog log;
  final VoidCallback? onDelete;

  const ActivityCard({super.key, required this.log, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _bgColor(colorScheme),
          child: Icon(_icon, color: _iconColor(colorScheme), size: 20),
        ),
        title: Text(
          Helpers.truncate(log.content, 80),
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          Helpers.formatDateTime(log.createdAt),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
                onPressed: onDelete,
                color: colorScheme.error,
                iconSize: 20,
              )
            : null,
      ),
    );
  }

  IconData get _icon {
    switch (log.entryType) {
      case LogEntryType.voice:
        return Icons.mic_rounded;
      case LogEntryType.vision:
        return Icons.camera_alt_rounded;
      case LogEntryType.note:
        return Icons.note_rounded;
      case LogEntryType.summary:
        return Icons.summarize_rounded;
    }
  }

  Color _bgColor(ColorScheme c) {
    switch (log.entryType) {
      case LogEntryType.voice:
        return c.primaryContainer;
      case LogEntryType.vision:
        return c.secondaryContainer;
      case LogEntryType.note:
        return c.tertiaryContainer;
      case LogEntryType.summary:
        return c.surfaceContainerHighest;
    }
  }

  Color _iconColor(ColorScheme c) {
    switch (log.entryType) {
      case LogEntryType.voice:
        return c.onPrimaryContainer;
      case LogEntryType.vision:
        return c.onSecondaryContainer;
      case LogEntryType.note:
        return c.onTertiaryContainer;
      case LogEntryType.summary:
        return c.onSurfaceVariant;
    }
  }
}

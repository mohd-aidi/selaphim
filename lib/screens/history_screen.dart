import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/conversation.dart';
import '../models/daily_log.dart';
import '../providers/activity_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/helpers.dart';
import '../widgets/activity_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  List<Conversation>? _searchResults;
  final TextEditingController _searchController = TextEditingController();
  int _tabIndex = 0; // 0 = conversations, 1 = daily logs

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _searchQuery = query);
    final settings = context.read<SettingsProvider>();
    final userId = settings.user?.id;
    if (userId == null) return;

    final activity = context.read<ActivityProvider>();
    final results = await activity.searchConversations(userId, query);
    if (mounted) setState(() => _searchResults = results);
  }

  Future<void> _export() async {
    final settings = context.read<SettingsProvider>();
    final userId = settings.user?.id;
    if (userId == null) return;
    final activity = context.read<ActivityProvider>();
    final text = await activity.exportHistory(userId);
    await Share.share(text, subject: 'Selaphim History Export');
  }

  Future<void> _confirmDeleteAll() async {
    final settings = context.read<SettingsProvider>();
    final userId = settings.user?.id;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All History?'),
        content: const Text(
            'This will permanently delete all conversations and logs.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ActivityProvider>().deleteAllHistory(userId);
      setState(() => _searchResults = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final activity = context.watch<ActivityProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final conversations =
        _searchQuery.isNotEmpty && _searchResults != null
            ? _searchResults!
            : activity.conversations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Export history',
            onPressed: _export,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded),
            tooltip: 'Delete all',
            onPressed: _confirmDeleteAll,
            color: colorScheme.error,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search conversations…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              _search('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _search,
                ),
              ),
              // Tab switcher
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Conversations')),
                    ButtonSegment(value: 1, label: Text('Daily Logs')),
                  ],
                  selected: {_tabIndex},
                  onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _tabIndex == 0
          ? _ConversationsTab(conversations: conversations)
          : _DailyLogsTab(logs: activity.todaysLogs),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ConversationsTab extends StatelessWidget {
  final List<Conversation> conversations;

  const _ConversationsTab({required this.conversations});

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final settings = context.read<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<Conversation>>{};
    for (final c in conversations) {
      final key = Helpers.formatDate(c.createdAt);
      grouped.putIfAbsent(key, () => []).add(c);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          for (final conv in entry.value)
            _ConversationTile(
              conversation: conv,
              onDelete: () async {
                final userId = settings.user?.id;
                if (userId == null) return;
                await activity.deleteConversation(conv.id, userId);
              },
            ),
        ],
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastMsg = conversation.messages.isNotEmpty
        ? conversation.messages.last.content
        : '(empty)';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: conversation.mode == ConversationMode.vision
              ? colorScheme.secondaryContainer
              : colorScheme.primaryContainer,
          child: Icon(
            conversation.mode == ConversationMode.vision
                ? Icons.camera_alt_rounded
                : Icons.mic_rounded,
            size: 20,
          ),
        ),
        title: Text(
          conversation.title ?? 'Conversation',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${Helpers.formatTime(conversation.createdAt)} · '
          '${conversation.messages.length} messages',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          color: colorScheme.error,
          tooltip: 'Delete',
          onPressed: onDelete,
        ),
        children: conversation.messages
            .where((m) => m.role != MessageRole.system)
            .map((m) => Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.role == MessageRole.user ? 'You: ' : 'AI: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: m.role == MessageRole.user
                              ? colorScheme.primary
                              : colorScheme.secondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          Helpers.truncate(m.content, 120),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _DailyLogsTab extends StatelessWidget {
  final List<DailyLog> logs;

  const _DailyLogsTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ActivityProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_rounded,
                size: 64, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No logs for today',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        return ActivityCard(
          log: logs[index],
          onDelete: () => activity.deleteLog(logs[index].id),
        );
      },
    );
  }
}

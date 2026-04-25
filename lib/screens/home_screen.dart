import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/activity_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/stat_tile.dart';
import 'vision_screen.dart';
import 'voice_assistant_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final settings = context.read<SettingsProvider>();
    final activity = context.read<ActivityProvider>();
    final conv = context.read<ConversationProvider>();

    // Wait until settings are loaded
    if (settings.loading) return;

    final userId = settings.user?.id;
    if (userId == null) return;

    conv.setUserId(userId);
    await activity.loadForUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          VisionScreen(),
          VoiceAssistantScreen(),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt_rounded),
            label: 'Vision',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic_rounded),
            label: 'Voice',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final activity = context.watch<ActivityProvider>();

    if (settings.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final userName = settings.user?.name ?? 'User';
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Selaphim'),
          floating: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_comment_rounded),
              tooltip: 'Add note',
              onPressed: () => _showAddNoteDialog(context),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_greeting()}, $userName!',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'How can I assist you today?',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Today's Activity",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Voice',
                    count: activity.voiceCount,
                    icon: Icons.mic_rounded,
                    color: colorScheme.primaryContainer,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    label: 'Vision',
                    count: activity.visionCount,
                    icon: Icons.camera_alt_rounded,
                    color: colorScheme.secondaryContainer,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    label: 'Notes',
                    count: activity.noteCount,
                    icon: Icons.note_rounded,
                    color: colorScheme.tertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Quick action buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.camera_alt_rounded,
                    label: 'Analyse Scene',
                    color: colorScheme.secondaryContainer,
                    onTap: () {
                      // Switch to vision tab
                      final state = context
                          .findAncestorStateOfType<_HomeScreenState>();
                      state?.setState(() => state._selectedIndex = 1);
                    },
                  ),
                ),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.mic_rounded,
                    label: 'Ask Assistant',
                    color: colorScheme.primaryContainer,
                    onTap: () {
                      final state = context
                          .findAncestorStateOfType<_HomeScreenState>();
                      state?.setState(() => state._selectedIndex = 2);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Recent activity
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        if (activity.loading)
          const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (activity.todaysLogs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 64, color: colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    'No activity yet today.\nTry the Vision or Voice tab!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final log = activity.todaysLogs[index];
                return ActivityCard(
                  log: log,
                  onDelete: () async {
                    await activity.deleteLog(log.id);
                  },
                );
              },
              childCount:
                  activity.todaysLogs.length.clamp(0, 5),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
    final controller = TextEditingController();
    final settings = context.read<SettingsProvider>();
    final activity = context.read<ActivityProvider>();
    final userId = settings.user?.id;
    if (userId == null) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Type your note here…',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                await activity.addNote(userId: userId, content: text);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

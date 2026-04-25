import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_provider.dart';
import '../providers/ai_personality_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  final Map<String, TextEditingController> _apiKeyControllers = {};
  final Map<String, bool> _obscureKey = {};
  final TextEditingController _aiNameController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    for (final p in AIProvider.values) {
      _apiKeyControllers[p.value] = TextEditingController();
      _obscureKey[p.value] = true;
    }
    _loadApiKeys();
  }

  Future<void> _loadApiKeys() async {
    final settings = context.read<SettingsProvider>();
    for (final p in AIProvider.values) {
      final key = await settings.getApiKey(p.value);
      if (key != null) {
        _apiKeyControllers[p.value]?.text = key;
      }
    }
    if (mounted) {
      _aiNameController.text = settings.aiName;
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final c in _apiKeyControllers.values) {
      c.dispose();
    }
    _aiNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = context.watch<SettingsProvider>();
    final personality = context.watch<AIPersonalityProvider>();
    final s = settings.settings;
    if (s == null) return const Center(child: CircularProgressIndicator());

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── User Profile ─────────────────────────────────────────────────
          _SectionHeader(label: 'Profile', icon: Icons.person_rounded),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                settings.user?.name.isNotEmpty == true
                    ? settings.user!.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(settings.user?.name ?? 'User'),
            subtitle: const Text('Tap to edit name'),
            trailing: const Icon(Icons.edit_rounded),
            onTap: () => _editName(context, settings),
          ),

          const Divider(),

          // ── AI Provider ───────────────────────────────────────────────────
          _SectionHeader(
              label: 'AI Provider', icon: Icons.smart_toy_rounded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<AIProvider>(
              value: s.aiProvider,
              decoration: const InputDecoration(
                labelText: 'Provider',
                prefixIcon: Icon(Icons.cloud_rounded),
              ),
              items: AIProvider.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.displayName),
                      ))
                  .toList(),
              onChanged: (provider) async {
                if (provider != null) {
                  await settings.setAIProvider(provider);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              value: s.aiModel,
              decoration: const InputDecoration(
                labelText: 'Model',
                prefixIcon: Icon(Icons.memory_rounded),
              ),
              items: s.aiProvider.availableModels
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (model) async {
                if (model != null) await settings.setAIModel(model);
              },
            ),
          ),

          // API Keys
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('API Keys',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )),
          ),
          for (final p in AIProvider.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _apiKeyControllers[p.value],
                obscureText: _obscureKey[p.value] ?? true,
                decoration: InputDecoration(
                  labelText: '${p.displayName} API Key',
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_obscureKey[p.value] == true
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded),
                        onPressed: () => setState(
                            () => _obscureKey[p.value] = !_obscureKey[p.value]!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.save_rounded),
                        tooltip: 'Save key',
                        onPressed: () async {
                          final key =
                              _apiKeyControllers[p.value]?.text.trim() ?? '';
                          await settings.saveApiKey(p.value, key);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${p.displayName} key saved securely')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const Divider(),

          // ── Voice & Speech ────────────────────────────────────────────────
          _SectionHeader(label: 'Voice & Speech', icon: Icons.record_voice_over_rounded),
          ListTile(
            leading: const Icon(Icons.speed_rounded),
            title: const Text('Speech Rate'),
            subtitle: Slider(
              value: s.ttsSpeed,
              min: 0.25,
              max: 2.0,
              divisions: 7,
              label: s.ttsSpeed.toStringAsFixed(2),
              onChanged: (v) => settings.updateSettings(s.copyWith(ttsSpeed: v)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Pitch'),
            subtitle: Slider(
              value: s.ttsPitch,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              label: s.ttsPitch.toStringAsFixed(2),
              onChanged: (v) => settings.updateSettings(s.copyWith(ttsPitch: v)),
            ),
          ),

          const Divider(),

          // ── Vision ────────────────────────────────────────────────────────
          _SectionHeader(label: 'Vision', icon: Icons.camera_alt_rounded),
          ListTile(
            leading: const Icon(Icons.timer_rounded),
            title: const Text('Live Mode Interval'),
            subtitle: Slider(
              value: s.liveVisionInterval.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              label: '${s.liveVisionInterval}s',
              onChanged: (v) => settings
                  .updateSettings(s.copyWith(liveVisionInterval: v.round())),
            ),
            trailing: Text('${s.liveVisionInterval}s'),
          ),

          const Divider(),

          // ── Appearance ────────────────────────────────────────────────────
          _SectionHeader(label: 'Appearance', icon: Icons.palette_rounded),
          RadioListTile<ThemeMode>(
            title: const Text('System default'),
            value: ThemeMode.system,
            groupValue: s.themeMode,
            onChanged: (v) => settings.setTheme(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: s.themeMode,
            onChanged: (v) => settings.setTheme(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: s.themeMode,
            onChanged: (v) => settings.setTheme(v!),
          ),

          const Divider(),

          // ── Notifications ─────────────────────────────────────────────────
          SwitchListTile(
            secondary: const Icon(Icons.notifications_rounded),
            title: const Text('Daily Notifications'),
            subtitle: const Text('Reminder to use the assistant'),
            value: s.notificationsEnabled,
            onChanged: (v) =>
                settings.updateSettings(s.copyWith(notificationsEnabled: v)),
          ),

          const Divider(),

          // ── Personality ───────────────────────────────────────────────────
          _SectionHeader(label: 'AI Personality', icon: Icons.face_rounded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _aiNameController,
                    decoration: const InputDecoration(
                      labelText: 'AI Name',
                      prefixIcon: Icon(Icons.smart_toy_rounded),
                      hintText: 'e.g. Selaphim',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.save_rounded),
                  tooltip: 'Save AI name',
                  onPressed: () async {
                    await settings.setAIName(_aiNameController.text);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'AI name updated to "${settings.aiName}"')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.military_tech_rounded),
            title: Text(
                'Level ${personality.skillLevel} — ${personality.levelTitle}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                    value: personality.levelProgress),
                const SizedBox(height: 4),
                Text('${personality.xp} XP  •  '
                    '${(personality.levelProgress * 100).round()}% to next level'),
              ],
            ),
            isThreeLine: true,
          ),

          const Divider(),

          // ── Self Learning ─────────────────────────────────────────────────
          _SectionHeader(
              label: 'Self Learning', icon: Icons.auto_stories_rounded),
          SwitchListTile(
            secondary: const Icon(Icons.camera_enhance_rounded),
            title: const Text('Enable Auto-Capture'),
            subtitle: const Text(
                'Periodically takes a photo for self-learning'),
            value: s.selfLearningEnabled,
            onChanged: (v) async {
              await settings.setSelfLearning(enabled: v);
            },
          ),
          if (s.selfLearningEnabled)
            ListTile(
              leading: const Icon(Icons.timer_rounded),
              title: const Text('Capture Interval'),
              subtitle: Slider(
                value: s.selfLearningIntervalMinutes.toDouble(),
                min: 15,
                max: 240,
                divisions: 15,
                label: '${s.selfLearningIntervalMinutes} min',
                onChanged: (v) => settings.updateSettings(
                    s.copyWith(selfLearningIntervalMinutes: v.round())),
              ),
              trailing: Text('${s.selfLearningIntervalMinutes} min'),
            ),

          const Divider(),

          // App info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('About Selaphim',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'AI Vision & Voice Assistant v1.0.0\n'
                        'Your daily life companion powered by OpenAI, '
                        'Google Gemini, or Anthropic Claude.'),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _editName(
      BuildContext context, SettingsProvider settings) async {
    final controller =
        TextEditingController(text: settings.user?.name ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Your name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await settings.updateUserName(name);
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

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

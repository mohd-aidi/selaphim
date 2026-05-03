import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tool_definition.dart';
import '../providers/ai_personality_provider.dart';
import '../services/tool_registry.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  @override
  Widget build(BuildContext context) {
    final personality = context.watch<AIPersonalityProvider>();
    final registry = ToolRegistry.instance;
    final allTools = registry.allTools;
    final skillLevel = personality.skillLevel;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Tools')),
      body: ListView(
        children: [
          // Skill level banner
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.military_tech_rounded,
                            color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Level $skillLevel — ${personality.levelTitle}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: personality.levelProgress,
                      backgroundColor: colorScheme.primaryContainer,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${personality.xp} XP  •  '
                      '${(personality.levelProgress * 100).round()}% to next level',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Available Tools',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          for (final tool in allTools)
            _ToolTile(
              tool: tool,
              unlocked: skillLevel >= tool.requiredSkillLevel,
              onToggle: (enabled) {
                registry.setEnabled(tool.id, enabled: enabled);
                setState(() {});
              },
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outlined, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Unlocked Skills',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: personality.unlockedSkills
                          .map((s) => Chip(label: Text(s)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final ToolDefinition tool;
  final bool unlocked;
  final void Function(bool) onToggle;

  const _ToolTile({
    required this.tool,
    required this.unlocked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        unlocked ? Icons.extension_rounded : Icons.lock_rounded,
        color: unlocked ? colorScheme.primary : colorScheme.outlineVariant,
      ),
      title: Text(tool.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tool.description),
          if (!unlocked)
            Text(
              'Requires skill level ${tool.requiredSkillLevel}',
              style: TextStyle(color: colorScheme.error, fontSize: 11),
            ),
        ],
      ),
      isThreeLine: !unlocked,
      trailing: Switch(
        value: tool.isEnabled && unlocked,
        onChanged: unlocked ? onToggle : null,
      ),
    );
  }
}

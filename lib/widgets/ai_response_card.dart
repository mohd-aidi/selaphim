import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/conversation.dart';
import '../utils/helpers.dart';

class AIResponseCard extends StatelessWidget {
  final Message message;
  final VoidCallback? onSpeak;
  final bool isSpeaking;

  const AIResponseCard({
    super.key,
    required this.message,
    this.onSpeak,
    this.isSpeaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Card(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Role label
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUser ? 'You' : 'Selaphim',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      Helpers.formatTime(message.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Message content
                SelectableText(
                  message.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                // Action row for assistant messages
                if (!isUser) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: isSpeaking
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_rounded,
                        tooltip: isSpeaking ? 'Stop' : 'Read aloud',
                        onTap: onSpeak,
                      ),
                      _ActionButton(
                        icon: Icons.copy_rounded,
                        tooltip: 'Copy',
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: message.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

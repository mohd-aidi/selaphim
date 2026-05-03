import 'package:flutter/material.dart';

/// A simple stat tile used on the home screen dashboard.
class StatTile extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color? color;

  const StatTile({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.primaryContainer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: effectiveColor,
              radius: 24,
              child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

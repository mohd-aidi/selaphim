import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/self_photo.dart';
import '../providers/ai_personality_provider.dart';
import '../providers/self_learning_provider.dart';
import '../providers/settings_provider.dart';

class SelfLearningScreen extends StatefulWidget {
  const SelfLearningScreen({super.key});

  @override
  State<SelfLearningScreen> createState() => _SelfLearningScreenState();
}

class _SelfLearningScreenState extends State<SelfLearningScreen> {
  CameraSide _selectedSide = CameraSide.back;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final settings = context.read<SettingsProvider>();
    final userId = settings.user?.id;
    if (userId == null) return;
    await context.read<SelfLearningProvider>().loadPhotos(userId);
  }

  Future<void> _capture() async {
    final settings = context.read<SettingsProvider>();
    final personality = context.read<AIPersonalityProvider>();
    final provider = context.read<SelfLearningProvider>();
    final userId = settings.user?.id;
    if (userId == null) return;

    await provider.capture(
      userId: userId,
      side: _selectedSide,
      aiProvider: settings.aiProvider,
      aiModel: settings.aiModel,
      personalityProvider: personality,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SelfLearningProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Learning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded),
            tooltip: 'Capture now',
            onPressed: provider.capturing ? null : _capture,
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera side selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<CameraSide>(
              segments: const [
                ButtonSegment(
                  value: CameraSide.back,
                  icon: Icon(Icons.camera_rear_rounded),
                  label: Text('Back Camera'),
                ),
                ButtonSegment(
                  value: CameraSide.front,
                  icon: Icon(Icons.camera_front_rounded),
                  label: Text('Front Camera'),
                ),
              ],
              selected: {_selectedSide},
              onSelectionChanged: (s) => setState(() => _selectedSide = s.first),
            ),
          ),

          if (provider.capturing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(),
            ),

          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                color: colorScheme.errorContainer,
                child: ListTile(
                  leading: Icon(Icons.error_outline,
                      color: colorScheme.onErrorContainer),
                  title: Text(provider.errorMessage!,
                      style:
                          TextStyle(color: colorScheme.onErrorContainer)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: provider.clearError,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              '${provider.photos.length} captured photo(s) stored locally',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),

          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.photos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_outlined,
                                size: 64,
                                color: colorScheme.outlineVariant),
                            const SizedBox(height: 12),
                            const Text('No self-learning photos yet.\n'
                                'Tap the camera icon to capture one.'),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: provider.photos.length,
                        itemBuilder: (ctx, i) {
                          final photo = provider.photos[i];
                          return _PhotoTile(
                            photo: photo,
                            onDelete: () =>
                                context
                                    .read<SelfLearningProvider>()
                                    .deletePhoto(photo),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.capturing ? null : _capture,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Capture'),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final SelfPhoto photo;
  final VoidCallback onDelete;

  const _PhotoTile({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _confirmDelete(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
            if (photo.aiLabel != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    photo.aiLabel!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 9),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  photo.cameraSide.value,
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this self-learning photo?'),
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
    if (confirmed == true) onDelete();
  }
}

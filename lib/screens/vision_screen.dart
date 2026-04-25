import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/conversation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/camera_service.dart';
import '../services/tts_service.dart';
import '../widgets/ai_response_card.dart';
import '../models/conversation.dart';

class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key});

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen>
    with AutomaticKeepAliveClientMixin {
  bool _cameraReady = false;
  bool _isLiveMode = false;
  String? _lastResponse;
  bool _isSpeaking = false;
  final TextEditingController _promptController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _promptController.text = 'Describe what you see in this image.';
    _initCamera();
  }

  Future<void> _initCamera() async {
    await CameraService.instance.init();
    if (mounted) setState(() => _cameraReady = true);
  }

  @override
  void dispose() {
    if (_isLiveMode) CameraService.instance.stopLiveStream();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyse() async {
    final bytes = await CameraService.instance.captureImage();
    if (bytes == null || !mounted) return;
    await _analyseBytes(bytes);
  }

  Future<void> _analyseBytes(Uint8List bytes) async {
    final settings = context.read<SettingsProvider>();
    final conv = context.read<ConversationProvider>();

    final reply = await conv.analyseImage(
      imageBytes: bytes,
      prompt: _promptController.text.trim().isEmpty
          ? 'Describe what you see in this image.'
          : _promptController.text.trim(),
      provider: settings.aiProvider,
      model: settings.aiModel,
    );

    if (reply != null && mounted) {
      setState(() => _lastResponse = reply);
      await TtsService.instance.speak(reply);
    }
  }

  void _toggleLiveMode() {
    final settings = context.read<SettingsProvider>();
    final interval = settings.settings?.liveVisionInterval ?? 10;

    if (_isLiveMode) {
      CameraService.instance.stopLiveStream();
      setState(() => _isLiveMode = false);
    } else {
      setState(() => _isLiveMode = true);
      CameraService.instance
          .startLiveStream(intervalSeconds: interval)
          .listen((bytes) => _analyseBytes(bytes));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final conv = context.watch<ConversationProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vision Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            tooltip: 'Switch camera',
            onPressed: _cameraReady
                ? () async {
                    await CameraService.instance.switchCamera();
                    setState(() {});
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _cameraReady &&
                      CameraService.instance.controller != null &&
                      CameraService.instance.isInitialized
                  ? Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CameraPreview(CameraService.instance.controller!),
                        if (_isLiveMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(180),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fiber_manual_record,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('LIVE',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              size: 64, color: Colors.white54),
                          SizedBox(height: 8),
                          Text(
                            'Camera unavailable',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Prompt input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                hintText: 'Enter a custom prompt…',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              textInputAction: TextInputAction.done,
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: conv.isLoading ? null : _captureAndAnalyse,
                    icon: const Icon(Icons.camera_rounded),
                    label: const Text('Analyse'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _cameraReady ? _toggleLiveMode : null,
                    icon: Icon(_isLiveMode
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline_rounded),
                    label: Text(_isLiveMode ? 'Stop Live' : 'Live Mode'),
                    style: _isLiveMode
                        ? FilledButton.styleFrom(
                            backgroundColor: colorScheme.errorContainer,
                            foregroundColor: colorScheme.onErrorContainer,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator
          if (conv.isLoading)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),

          // Error
          if (conv.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                color: colorScheme.errorContainer,
                child: ListTile(
                  leading: Icon(Icons.error_outline,
                      color: colorScheme.onErrorContainer),
                  title: Text(conv.errorMessage!,
                      style: TextStyle(color: colorScheme.onErrorContainer)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: conv.clearError,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),

          // Response area
          if (_lastResponse != null)
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: conv.current?.messages.isNotEmpty == true
                    ? AIResponseCard(
                        message: conv.current!.messages.last,
                        isSpeaking: _isSpeaking,
                        onSpeak: () async {
                          setState(() => _isSpeaking = !_isSpeaking);
                          if (_isSpeaking) {
                            await TtsService.instance.speak(_lastResponse!);
                            setState(() => _isSpeaking = false);
                          } else {
                            await TtsService.instance.stop();
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

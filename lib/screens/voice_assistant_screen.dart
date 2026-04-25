import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../providers/conversation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../widgets/ai_response_card.dart';
import '../widgets/voice_input_button.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isListening = false;
  bool _isSpeaking = false;
  String _liveTranscript = '';
  String? _speakingMessageId;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await SpeechService.instance.init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    SpeechService.instance.cancel();
    super.dispose();
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _liveTranscript = '';
    });

    final settings = context.read<SettingsProvider>();
    final locale = settings.settings?.languageCode.replaceAll('-', '_') ?? 'en_US';

    final started = await SpeechService.instance.startListening(
      localeId: locale,
      onResult: (text, isFinal) {
        setState(() => _liveTranscript = text);
        if (isFinal && text.isNotEmpty) {
          _stopListening();
          _sendMessage(text);
        }
      },
    );

    if (!started && mounted) {
      setState(() => _isListening = false);
      _showError('Microphone access denied or speech not available.');
    }
  }

  Future<void> _stopListening() async {
    await SpeechService.instance.stopListening();
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    final settings = context.read<SettingsProvider>();
    final conv = context.read<ConversationProvider>();

    final userId = settings.user?.id;
    if (userId == null) return;

    if (conv.current == null) {
      conv.startNewConversation(
        mode: ConversationMode.voice,
        userId: userId,
      );
    }

    final reply = await conv.sendMessage(
      userMessage: text,
      provider: settings.aiProvider,
      model: settings.aiModel,
    );

    if (reply != null && mounted) {
      setState(() => _isSpeaking = true);
      TtsService.instance.setHandlers(
        onComplete: () {
          if (mounted) setState(() => _isSpeaking = false);
        },
      );
      await TtsService.instance.speak(reply);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final conv = context.watch<ConversationProvider>();
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final messages = conv.current?.messages
            .where((m) => m.role != MessageRole.system)
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New conversation',
            onPressed: () {
              final userId = settings.user?.id;
              if (userId == null) return;
              conv.startNewConversation(
                mode: ConversationMode.voice,
                userId: userId,
              );
              setState(() {
                _liveTranscript = '';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty && _liveTranscript.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_rounded,
                            size: 80,
                            color: colorScheme.primaryContainer),
                        const SizedBox(height: 16),
                        Text(
                          'Tap the microphone to start',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask anything – I\'m here to help!',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return AIResponseCard(
                        message: msg,
                        isSpeaking: _isSpeaking &&
                            _speakingMessageId == msg.id,
                        onSpeak: () async {
                          if (_isSpeaking && _speakingMessageId == msg.id) {
                            await TtsService.instance.stop();
                            setState(() => _isSpeaking = false);
                          } else {
                            setState(() {
                              _isSpeaking = true;
                              _speakingMessageId = msg.id;
                            });
                            await TtsService.instance.speak(msg.content);
                            if (mounted) setState(() => _isSpeaking = false);
                          }
                        },
                      );
                    },
                  ),
          ),

          // Live transcript bubble
          if (_isListening)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _liveTranscript.isEmpty
                          ? 'Listening…'
                          : _liveTranscript,
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),

          // Error
          if (conv.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                color: colorScheme.errorContainer,
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.error_outline,
                      color: colorScheme.onErrorContainer, size: 20),
                  title: Text(
                    conv.errorMessage!,
                    style:
                        TextStyle(color: colorScheme.onErrorContainer),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: conv.clearError,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),

          if (conv.isLoading) const LinearProgressIndicator(),

          // Text input + mic
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Or type your message…',
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) => _sendMessage(text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: conv.isLoading
                        ? null
                        : () => _sendMessage(_textController.text),
                    icon: const Icon(Icons.send_rounded),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: VoiceInputButton(
        isListening: _isListening,
        onPressed: conv.isLoading ? () {} : _toggleListening,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

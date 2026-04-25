import 'package:flutter/material.dart';

class VoiceInputButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const VoiceInputButton({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!widget.isListening) {
      return FloatingActionButton.large(
        onPressed: widget.onPressed,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        tooltip: 'Tap to speak',
        child: const Icon(Icons.mic_rounded, size: 40),
      );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton.large(
            onPressed: widget.onPressed,
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            tooltip: 'Tap to stop',
            child: const Icon(Icons.stop_rounded, size: 40),
          ),
        );
      },
    );
  }
}

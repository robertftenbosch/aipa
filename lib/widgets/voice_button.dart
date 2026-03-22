import 'package:flutter/material.dart';

class VoiceButton extends StatelessWidget {
  final bool isListening;
  final bool isAvailable;
  final VoidCallback? onPressed;

  const VoiceButton({
    super.key,
    required this.isListening,
    required this.isAvailable,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAvailable) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isListening
              ? Colors.red
              : Theme.of(context).colorScheme.secondary,
          shape: BoxShape.circle,
          boxShadow: isListening
              ? [
                  BoxShadow(
                    color: Colors.red.withAlpha(100),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(
          isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

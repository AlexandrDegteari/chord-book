import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

class ChordDetectorOverlay extends StatelessWidget {
  final String detectedChord;
  final String detectedNote;
  final bool isListening;
  final String? error;
  final VoidCallback onToggle;

  const ChordDetectorOverlay({
    super.key,
    required this.detectedChord,
    required this.detectedNote,
    required this.isListening,
    required this.onToggle,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        right: DesignTokens.spacingMd,
        bottom: DesignTokens.spacingMd,
        left: DesignTokens.spacingMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (error != null)
            Container(
              margin: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
              padding: const EdgeInsets.all(DesignTokens.spacingSm),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Text(error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12)),
            ),
          if (isListening && detectedChord.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingSm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_note,
                      color: theme.colorScheme.onPrimaryContainer, size: 20),
                  const SizedBox(width: DesignTokens.spacingSm),
                  Text(
                    detectedChord,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          if (isListening && detectedChord.isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingSm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: DesignTokens.spacingSm),
                  Text('Listening...',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                ],
              ),
            ),
          FloatingActionButton(
            heroTag: 'mic_toggle',
            onPressed: onToggle,
            backgroundColor:
                isListening ? theme.colorScheme.error : theme.colorScheme.primary,
            child: Icon(isListening ? Icons.mic_off : Icons.mic, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

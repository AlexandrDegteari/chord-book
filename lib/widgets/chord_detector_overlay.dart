import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

class ChordDetectorOverlay extends StatelessWidget {
  final String detectedChord;
  final double confidence;
  final bool isListening;
  final VoidCallback onToggle;

  const ChordDetectorOverlay({
    super.key,
    required this.detectedChord,
    required this.confidence,
    required this.isListening,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      bottom: DesignTokens.spacingMd,
      left: DesignTokens.spacingMd,
      right: DesignTokens.spacingMd,
      child: Row(
        children: [
          // Mic toggle button
          FloatingActionButton(
            heroTag: 'mic_toggle',
            onPressed: onToggle,
            backgroundColor: isListening
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            child: Icon(
              isListening ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            ),
          ),
          if (isListening && detectedChord.isNotEmpty) ...[
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Container(
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
                    Icon(
                      Icons.music_note,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
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
                    const Spacer(),
                    // Confidence indicator
                    SizedBox(
                      width: 40,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: confidence,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.outline
                              .withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation(
                            confidence > 0.7
                                ? Colors.green
                                : confidence > 0.5
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isListening && detectedChord.isEmpty) ...[
            const SizedBox(width: DesignTokens.spacingMd),
            Container(
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
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingSm),
                  Text(
                    'Listening...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

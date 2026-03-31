import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../config/design_tokens.dart';
import 'chord_diagram.dart';

class ChordDetectorOverlay extends StatefulWidget {
  final String detectedChord;
  final String detectedNote;
  final bool isListening;
  final String? error;
  final VoidCallback onToggle;
  final String? currentSongChord; // The chord user should play now (from song)

  const ChordDetectorOverlay({
    super.key,
    required this.detectedChord,
    required this.detectedNote,
    required this.isListening,
    required this.onToggle,
    this.error,
    this.currentSongChord,
  });

  @override
  State<ChordDetectorOverlay> createState() => _ChordDetectorOverlayState();
}

class _ChordDetectorOverlayState extends State<ChordDetectorOverlay> {
  bool _showDiagram = false;

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
          // Error
          if (widget.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
              padding: const EdgeInsets.all(DesignTokens.spacingSm),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Text(widget.error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12)),
            ),

          // Chord diagram popup
          if (_showDiagram && widget.currentSongChord != null && widget.currentSongChord!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ChordDiagram(
                chordName: widget.currentSongChord!,
                size: 140,
              ),
            ),

          // Detected chord badge (only when listening)
          if (widget.isListening && widget.detectedChord.isNotEmpty)
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
                    widget.detectedChord,
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

          if (widget.isListening && widget.detectedChord.isEmpty)
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
                  Text(AppLocalizations.of(context)!.listening,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                ],
              ),
            ),

          // Button row: diagram toggle + mic toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Chord diagram button
              if (widget.currentSongChord != null && widget.currentSongChord!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FloatingActionButton.small(
                    heroTag: 'chord_diagram',
                    onPressed: () => setState(() => _showDiagram = !_showDiagram),
                    backgroundColor: _showDiagram
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.grid_on,
                      color: _showDiagram
                          ? theme.colorScheme.onTertiary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
              // Mic toggle
              FloatingActionButton(
                heroTag: 'mic_toggle',
                onPressed: widget.onToggle,
                backgroundColor: widget.isListening
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                child: Icon(
                  widget.isListening ? Icons.mic_off : Icons.mic,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

enum ChordBadgeState { normal, current, next }

class ChordBadge extends StatelessWidget {
  final String chord;
  final ChordBadgeState state;

  const ChordBadge({
    super.key,
    required this.chord,
    this.state = ChordBadgeState.normal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (state) {
      case ChordBadgeState.current:
        // Green — currently playing
        return Container(
          padding: DesignTokens.chordBadgePadding,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            chord,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'monospace',
            ),
          ),
        );

      case ChordBadgeState.next:
        // Orange — next on deck
        return Container(
          padding: DesignTokens.chordBadgePadding,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            chord,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'monospace',
            ),
          ),
        );

      case ChordBadgeState.normal:
        return Container(
          padding: DesignTokens.chordBadgePadding,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
          child: Text(
            chord,
            style: TextStyle(
              color: theme.colorScheme.primary.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        );
    }
  }
}

import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

class ChordBadge extends StatelessWidget {
  final String chord;
  final bool isActive;

  const ChordBadge({
    super.key,
    required this.chord,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.8);

    return Container(
      padding: DesignTokens.chordBadgePadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isActive ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: isActive
            ? Border.all(color: color, width: 1.5)
            : null,
      ),
      child: Text(
        chord,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

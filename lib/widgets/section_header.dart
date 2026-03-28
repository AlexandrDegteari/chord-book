import 'package:flutter/material.dart';
import '../config/design_tokens.dart';
import '../models/song_section.dart';

class SectionHeader extends StatelessWidget {
  final SongSection section;

  const SectionHeader({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChorus = section.type == SectionType.chorus;

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spacingMd, bottom: DesignTokens.spacingSm),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: isChorus
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: DesignTokens.spacingSm),
          Text(
            section.label.isNotEmpty
                ? section.label
                : section.type.name.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isChorus
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

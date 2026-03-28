import 'package:flutter/material.dart';
import '../models/song_section.dart';
import 'chord_badge.dart';

class ChordLineWidget extends StatelessWidget {
  final SongLine line;
  final String? activeChord;
  final double fontSize;

  const ChordLineWidget({
    super.key,
    required this.line,
    this.activeChord,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (line.chords.isEmpty && line.lyrics.isEmpty) {
      return const SizedBox(height: 12);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (line.chords.isNotEmpty)
            Wrap(
              spacing: 8,
              children: line.chords.map((chord) {
                final isActive = activeChord != null &&
                    chord.display.toLowerCase() == activeChord!.toLowerCase();
                return ChordBadge(
                  chord: chord.display,
                  isActive: isActive,
                );
              }).toList(),
            ),
          if (line.lyrics.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: line.chords.isNotEmpty ? 2 : 0),
              child: Text(
                line.lyrics,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

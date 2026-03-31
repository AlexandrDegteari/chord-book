import 'package:flutter/material.dart';
import '../models/song_section.dart';
import 'chord_badge.dart';

class ChordLineWidget extends StatelessWidget {
  final SongLine line;
  final double fontSize;
  final int sectionIndex;
  final int lineIndex;
  final Set<String> currentChordKeys; // Keys like "s:l:c" for current chord
  final Set<String> nextChordKeys; // Keys like "s:l:c" for next chord

  const ChordLineWidget({
    super.key,
    required this.line,
    this.fontSize = 16,
    this.sectionIndex = 0,
    this.lineIndex = 0,
    this.currentChordKeys = const {},
    this.nextChordKeys = const {},
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
              children: List.generate(line.chords.length, (chordIdx) {
                final chord = line.chords[chordIdx];
                final key = '$sectionIndex:$lineIndex:$chordIdx';
                final isCurrent = currentChordKeys.contains(key);
                final isNext = nextChordKeys.contains(key);

                return ChordBadge(
                  chord: chord.display,
                  state: isCurrent
                      ? ChordBadgeState.current
                      : isNext
                          ? ChordBadgeState.next
                          : ChordBadgeState.normal,
                );
              }),
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

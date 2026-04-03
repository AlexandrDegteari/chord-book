import 'package:flutter/material.dart';

/// Guitar chord diagram widget — draws fretboard with finger positions.
class ChordDiagram extends StatelessWidget {
  final String chordName;
  final double size;

  const ChordDiagram({super.key, required this.chordName, this.size = 160});

  @override
  Widget build(BuildContext context) {
    final data = _lookupChord(chordName);
    if (data == null) {
      return SizedBox(
        width: size,
        height: size * 1.2,
        child: Center(
          child: Text(chordName, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          )),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size * 1.3,
      child: CustomPaint(
        painter: _ChordDiagramPainter(
          frets: data.frets,
          fingers: data.fingers,
          baseFret: data.baseFret,
          barres: data.barres,
          chordName: chordName,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }

  static _ChordInfo? _lookupChord(String name) {
    final trimmed = name.trim();
    // Try exact match first (e.g. Gm/Bb)
    final exact = _chordData[trimmed];
    if (exact != null) return exact;
    // Fallback: strip bass note
    final slashIdx = trimmed.indexOf('/');
    if (slashIdx > 0) {
      return _chordData[trimmed.substring(0, slashIdx)];
    }
    return null;
  }

  // Chord data: frets = [E,A,D,G,B,e], -1 = muted, 0 = open
  static final Map<String, _ChordInfo> _chordData = {
    // ── Major ──
    'C':  _ChordInfo([0, 3, 2, 0, 1, 0], [0, 3, 2, 0, 1, 0], 1, []),
    'D':  _ChordInfo([-1, -1, 0, 2, 3, 2], [0, 0, 0, 1, 3, 2], 1, []),
    'E':  _ChordInfo([0, 2, 2, 1, 0, 0], [0, 2, 3, 1, 0, 0], 1, []),
    'F':  _ChordInfo([1, 1, 2, 3, 3, 1], [1, 1, 2, 3, 4, 1], 1, [1]),
    'G':  _ChordInfo([3, 2, 0, 0, 0, 3], [2, 1, 0, 0, 0, 3], 1, []),
    'A':  _ChordInfo([0, 0, 2, 2, 2, 0], [0, 0, 1, 2, 3, 0], 1, []),
    'B':  _ChordInfo([-1, 2, 4, 4, 4, 2], [0, 1, 2, 3, 4, 1], 2, [2]),
    'C#': _ChordInfo([-1, 4, 6, 6, 6, 4], [0, 1, 2, 3, 4, 1], 4, [4]),
    'Db': _ChordInfo([-1, 4, 6, 6, 6, 4], [0, 1, 2, 3, 4, 1], 4, [4]),
    'D#': _ChordInfo([-1, -1, 1, 3, 4, 3], [0, 0, 1, 2, 4, 3], 1, []),
    'Eb': _ChordInfo([-1, -1, 1, 3, 4, 3], [0, 0, 1, 2, 4, 3], 1, []),
    'F#': _ChordInfo([2, 4, 4, 3, 2, 2], [1, 3, 4, 2, 1, 1], 2, [2]),
    'Gb': _ChordInfo([2, 4, 4, 3, 2, 2], [1, 3, 4, 2, 1, 1], 2, [2]),
    'G#': _ChordInfo([4, 6, 6, 5, 4, 4], [1, 3, 4, 2, 1, 1], 4, [4]),
    'Ab': _ChordInfo([4, 6, 6, 5, 4, 4], [1, 3, 4, 2, 1, 1], 4, [4]),
    'A#': _ChordInfo([-1, 1, 3, 3, 3, 1], [0, 1, 2, 3, 4, 1], 1, [1]),
    'Bb': _ChordInfo([-1, 1, 3, 3, 3, 1], [0, 1, 2, 3, 4, 1], 1, [1]),

    // ── Minor ──
    'Am':  _ChordInfo([0, 0, 2, 2, 1, 0], [0, 0, 2, 3, 1, 0], 1, []),
    'Bm':  _ChordInfo([-1, 2, 4, 4, 3, 2], [0, 1, 3, 4, 2, 1], 2, [2]),
    'Cm':  _ChordInfo([-1, 3, 5, 5, 4, 3], [0, 1, 3, 4, 2, 1], 3, [3]),
    'Dm':  _ChordInfo([-1, -1, 0, 2, 3, 1], [0, 0, 0, 2, 3, 1], 1, []),
    'Em':  _ChordInfo([0, 2, 2, 0, 0, 0], [0, 2, 3, 0, 0, 0], 1, []),
    'Fm':  _ChordInfo([1, 1, 3, 3, 2, 1], [1, 1, 3, 4, 2, 1], 1, [1]),
    'Gm':  _ChordInfo([3, 1, 0, 0, 3, 3], [2, 1, 0, 0, 3, 4], 1, []),
    'C#m': _ChordInfo([-1, 4, 6, 6, 5, 4], [0, 1, 3, 4, 2, 1], 4, [4]),
    'Dbm': _ChordInfo([-1, 4, 6, 6, 5, 4], [0, 1, 3, 4, 2, 1], 4, [4]),
    'D#m': _ChordInfo([-1, -1, 1, 3, 4, 2], [0, 0, 1, 3, 4, 2], 1, []),
    'Ebm': _ChordInfo([-1, -1, 1, 3, 4, 2], [0, 0, 1, 3, 4, 2], 1, []),
    'F#m': _ChordInfo([2, 4, 4, 2, 2, 2], [1, 3, 4, 1, 1, 1], 2, [2]),
    'Gbm': _ChordInfo([2, 4, 4, 2, 2, 2], [1, 3, 4, 1, 1, 1], 2, [2]),
    'G#m': _ChordInfo([4, 6, 6, 4, 4, 4], [1, 3, 4, 1, 1, 1], 4, [4]),
    'Abm': _ChordInfo([4, 6, 6, 4, 4, 4], [1, 3, 4, 1, 1, 1], 4, [4]),
    'A#m': _ChordInfo([-1, 1, 3, 3, 2, 1], [0, 1, 3, 4, 2, 1], 1, [1]),
    'Bbm': _ChordInfo([-1, 1, 3, 3, 2, 1], [0, 1, 3, 4, 2, 1], 1, [1]),

    // ── Slash Chords ──
    'C/E':   _ChordInfo([0, 3, 2, 0, 1, 0], [0, 3, 2, 0, 1, 0], 1, []),
    'C/G':   _ChordInfo([3, 3, 2, 0, 1, 0], [3, 3, 2, 0, 1, 0], 1, []),
    'D/F#':  _ChordInfo([2, 0, 0, 2, 3, 2], [1, 0, 0, 2, 3, 2], 1, []),
    'Am/C':  _ChordInfo([-1, 3, 2, 2, 1, 0], [0, 4, 2, 3, 1, 0], 1, []),
    'Am/E':  _ChordInfo([0, 0, 2, 2, 1, 0], [0, 0, 2, 3, 1, 0], 1, []),
    'Am/G':  _ChordInfo([3, 0, 2, 2, 1, 0], [4, 0, 2, 3, 1, 0], 1, []),
    'G/B':   _ChordInfo([-1, 2, 0, 0, 0, 3], [0, 1, 0, 0, 0, 3], 1, []),
    'G/D':   _ChordInfo([-1, -1, 0, 0, 0, 3], [0, 0, 0, 0, 0, 1], 1, []),
    'Em/G':  _ChordInfo([3, 2, 2, 0, 0, 0], [3, 2, 1, 0, 0, 0], 1, []),
    'F/C':   _ChordInfo([-1, 3, 3, 2, 1, 1], [0, 3, 4, 2, 1, 1], 1, [1]),
    'F/A':   _ChordInfo([0, 0, 3, 2, 1, 1], [0, 0, 3, 2, 1, 1], 1, []),
    'Dm/F':  _ChordInfo([1, 0, 0, 2, 3, 1], [1, 0, 0, 2, 4, 1], 1, []),
    'Dm/A':  _ChordInfo([-1, 0, 0, 2, 3, 1], [0, 0, 0, 2, 3, 1], 1, []),
    'Em/B':  _ChordInfo([-1, 2, 2, 0, 0, 0], [0, 2, 3, 0, 0, 0], 1, []),
    'A/C#':  _ChordInfo([-1, 4, 2, 2, 2, 0], [0, 4, 1, 2, 3, 0], 1, []),
    'A/E':   _ChordInfo([0, 0, 2, 2, 2, 0], [0, 0, 1, 2, 3, 0], 1, []),
    'E/G#':  _ChordInfo([4, 2, 2, 1, 0, 0], [4, 2, 3, 1, 0, 0], 1, []),
    'Gm/Bb': _ChordInfo([-1, 1, 0, 0, 3, 3], [0, 1, 0, 0, 3, 4], 1, []),
    'Gm/D':  _ChordInfo([-1, -1, 0, 3, 3, 3], [0, 0, 0, 1, 2, 3], 1, []),
    'Dm/C':  _ChordInfo([-1, 3, 0, 2, 3, 1], [0, 3, 0, 2, 4, 1], 1, []),
    'Em/D':  _ChordInfo([-1, -1, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0], 1, []),
    'Bm/D':  _ChordInfo([-1, -1, 0, 4, 3, 2], [0, 0, 0, 4, 3, 2], 1, []),
    'Bm/F#': _ChordInfo([2, 2, 4, 4, 3, 2], [1, 1, 3, 4, 2, 1], 2, [2]),

    // ── Power Chords (5) ──
    'C5':  _ChordInfo([-1, 3, 5, 5, -1, -1], [0, 1, 3, 4, 0, 0], 3, []),
    'D5':  _ChordInfo([-1, -1, 0, 2, 3, -1], [0, 0, 0, 1, 2, 0], 1, []),
    'E5':  _ChordInfo([0, 2, 2, -1, -1, -1], [0, 1, 2, 0, 0, 0], 1, []),
    'F5':  _ChordInfo([1, 3, 3, -1, -1, -1], [1, 3, 4, 0, 0, 0], 1, []),
    'G5':  _ChordInfo([3, 5, 5, -1, -1, -1], [1, 3, 4, 0, 0, 0], 3, []),
    'A5':  _ChordInfo([-1, 0, 2, 2, -1, -1], [0, 0, 1, 2, 0, 0], 1, []),
    'B5':  _ChordInfo([-1, 2, 4, 4, -1, -1], [0, 1, 3, 4, 0, 0], 2, []),

    'C#5': _ChordInfo([-1, 4, 6, 6, -1, -1], [0, 1, 3, 4, 0, 0], 4, []),
    'D#5': _ChordInfo([-1, -1, 1, 3, 4, -1], [0, 0, 1, 3, 4, 0], 1, []),
    'Eb5': _ChordInfo([-1, -1, 1, 3, 4, -1], [0, 0, 1, 3, 4, 0], 1, []),
    'F#5': _ChordInfo([2, 4, 4, -1, -1, -1], [1, 3, 4, 0, 0, 0], 2, []),
    'G#5': _ChordInfo([4, 6, 6, -1, -1, -1], [1, 3, 4, 0, 0, 0], 4, []),
    'Bb5': _ChordInfo([-1, 1, 3, 3, -1, -1], [0, 1, 3, 4, 0, 0], 1, []),
    'Ab5': _ChordInfo([4, 6, 6, -1, -1, -1], [1, 3, 4, 0, 0, 0], 4, []),
    'Db5': _ChordInfo([-1, 4, 6, 6, -1, -1], [0, 1, 3, 4, 0, 0], 4, []),
    'Gb5': _ChordInfo([2, 4, 4, -1, -1, -1], [1, 3, 4, 0, 0, 0], 2, []),

    // ── Dominant 7th ──
    'A7':  _ChordInfo([0, 0, 2, 0, 2, 0], [0, 0, 2, 0, 3, 0], 1, []),
    'B7':  _ChordInfo([-1, 2, 1, 2, 0, 2], [0, 2, 1, 3, 0, 4], 1, []),
    'C7':  _ChordInfo([0, 3, 2, 3, 1, 0], [0, 3, 2, 4, 1, 0], 1, []),
    'D7':  _ChordInfo([-1, -1, 0, 2, 1, 2], [0, 0, 0, 2, 1, 3], 1, []),
    'E7':  _ChordInfo([0, 2, 0, 1, 0, 0], [0, 2, 0, 1, 0, 0], 1, []),
    'F7':  _ChordInfo([1, 3, 1, 2, 1, 1], [1, 3, 1, 2, 1, 1], 1, [1]),
    'G7':  _ChordInfo([3, 2, 0, 0, 0, 1], [3, 2, 0, 0, 0, 1], 1, []),
    'C#7': _ChordInfo([-1, 4, 3, 4, 2, -1], [0, 3, 2, 4, 1, 0], 2, []),
    'Db7': _ChordInfo([-1, 4, 3, 4, 2, -1], [0, 3, 2, 4, 1, 0], 2, []),
    'D#7': _ChordInfo([-1, -1, 1, 3, 2, 3], [0, 0, 1, 3, 2, 4], 1, []),
    'Eb7': _ChordInfo([-1, -1, 1, 3, 2, 3], [0, 0, 1, 3, 2, 4], 1, []),
    'F#7': _ChordInfo([2, 4, 2, 3, 2, 2], [1, 3, 1, 2, 1, 1], 2, [2]),
    'Gb7': _ChordInfo([2, 4, 2, 3, 2, 2], [1, 3, 1, 2, 1, 1], 2, [2]),
    'G#7': _ChordInfo([4, 6, 4, 5, 4, 4], [1, 3, 1, 2, 1, 1], 4, [4]),
    'Ab7': _ChordInfo([4, 6, 4, 5, 4, 4], [1, 3, 1, 2, 1, 1], 4, [4]),
    'A#7': _ChordInfo([-1, 1, 3, 1, 3, 1], [0, 1, 3, 1, 4, 1], 1, [1]),
    'Bb7': _ChordInfo([-1, 1, 3, 1, 3, 1], [0, 1, 3, 1, 4, 1], 1, [1]),

    // ── Minor 7th ──
    'Am7':  _ChordInfo([0, 0, 2, 0, 1, 0], [0, 0, 2, 0, 1, 0], 1, []),
    'Bm7':  _ChordInfo([-1, 2, 0, 2, 0, 2], [0, 2, 0, 3, 0, 4], 1, []),
    'Cm7':  _ChordInfo([-1, 3, 5, 3, 4, 3], [0, 1, 3, 1, 2, 1], 3, [3]),
    'Dm7':  _ChordInfo([-1, -1, 0, 2, 1, 1], [0, 0, 0, 2, 1, 1], 1, []),
    'Em7':  _ChordInfo([0, 2, 0, 0, 0, 0], [0, 1, 0, 0, 0, 0], 1, []),
    'Fm7':  _ChordInfo([1, 3, 1, 1, 1, 1], [1, 3, 1, 1, 1, 1], 1, [1]),
    'Gm7':  _ChordInfo([3, 5, 3, 3, 3, 3], [1, 3, 1, 1, 1, 1], 3, [3]),
    'C#m7': _ChordInfo([-1, 4, 6, 4, 5, 4], [0, 1, 3, 1, 2, 1], 4, [4]),
    'Dbm7': _ChordInfo([-1, 4, 6, 4, 5, 4], [0, 1, 3, 1, 2, 1], 4, [4]),
    'D#m7': _ChordInfo([-1, -1, 1, 3, 2, 2], [0, 0, 1, 4, 2, 3], 1, []),
    'Ebm7': _ChordInfo([-1, -1, 1, 3, 2, 2], [0, 0, 1, 4, 2, 3], 1, []),
    'F#m7': _ChordInfo([2, 4, 2, 2, 2, 2], [1, 3, 1, 1, 1, 1], 2, [2]),
    'Gbm7': _ChordInfo([2, 4, 2, 2, 2, 2], [1, 3, 1, 1, 1, 1], 2, [2]),
    'G#m7': _ChordInfo([4, 6, 4, 4, 4, 4], [1, 3, 1, 1, 1, 1], 4, [4]),
    'Abm7': _ChordInfo([4, 6, 4, 4, 4, 4], [1, 3, 1, 1, 1, 1], 4, [4]),
    'A#m7': _ChordInfo([-1, 1, 3, 1, 2, 1], [0, 1, 3, 1, 2, 1], 1, [1]),
    'Bbm7': _ChordInfo([-1, 1, 3, 1, 2, 1], [0, 1, 3, 1, 2, 1], 1, [1]),

    // ── Major 7th ──
    'Cmaj7':  _ChordInfo([0, 3, 2, 0, 0, 0], [0, 3, 2, 0, 0, 0], 1, []),
    'Dmaj7':  _ChordInfo([-1, -1, 0, 2, 2, 2], [0, 0, 0, 1, 2, 3], 1, []),
    'Emaj7':  _ChordInfo([0, 2, 1, 1, 0, 0], [0, 3, 1, 2, 0, 0], 1, []),
    'Fmaj7':  _ChordInfo([-1, -1, 3, 2, 1, 0], [0, 0, 3, 2, 1, 0], 1, []),
    'Gmaj7':  _ChordInfo([3, 2, 0, 0, 0, 2], [2, 1, 0, 0, 0, 3], 1, []),
    'Amaj7':  _ChordInfo([-1, 0, 2, 1, 2, 0], [0, 0, 3, 1, 4, 0], 1, []),
    'Bmaj7':  _ChordInfo([-1, 2, 4, 3, 4, 2], [0, 1, 3, 2, 4, 1], 2, [2]),
    'C#maj7': _ChordInfo([-1, 4, 6, 5, 6, 4], [0, 1, 3, 2, 4, 1], 4, [4]),
    'Dbmaj7': _ChordInfo([-1, 4, 6, 5, 6, 4], [0, 1, 3, 2, 4, 1], 4, [4]),
    'D#maj7': _ChordInfo([-1, -1, 1, 3, 3, 3], [0, 0, 1, 2, 3, 4], 1, []),
    'Ebmaj7': _ChordInfo([-1, -1, 1, 3, 3, 3], [0, 0, 1, 2, 3, 4], 1, []),
    'F#maj7': _ChordInfo([2, 4, 3, 3, 2, 2], [1, 4, 2, 3, 1, 1], 2, [2]),
    'Gbmaj7': _ChordInfo([2, 4, 3, 3, 2, 2], [1, 4, 2, 3, 1, 1], 2, [2]),
    'G#maj7': _ChordInfo([4, 6, 5, 5, 4, 4], [1, 4, 2, 3, 1, 1], 4, [4]),
    'Abmaj7': _ChordInfo([4, 6, 5, 5, 4, 4], [1, 4, 2, 3, 1, 1], 4, [4]),
    'A#maj7': _ChordInfo([-1, 1, 3, 2, 3, 1], [0, 1, 3, 2, 4, 1], 1, [1]),
    'Bbmaj7': _ChordInfo([-1, 1, 3, 2, 3, 1], [0, 1, 3, 2, 4, 1], 1, [1]),

    // ── Suspended 2 ──
    'Asus2': _ChordInfo([0, 0, 2, 2, 0, 0], [0, 0, 1, 2, 0, 0], 1, []),
    'Bsus2': _ChordInfo([-1, 2, 4, 4, 2, 2], [0, 1, 3, 4, 1, 1], 2, [2]),
    'Csus2': _ChordInfo([-1, 3, 5, 5, 3, 3], [0, 1, 3, 4, 1, 1], 3, [3]),
    'Dsus2': _ChordInfo([-1, -1, 0, 2, 3, 0], [0, 0, 0, 1, 3, 0], 1, []),
    'Esus2': _ChordInfo([0, 2, 4, 4, 0, 0], [0, 1, 3, 4, 0, 0], 1, []),
    'Fsus2': _ChordInfo([-1, -1, 3, 0, 1, 1], [0, 0, 3, 0, 1, 1], 1, []),
    'Gsus2': _ChordInfo([3, 0, 0, 0, 3, 3], [1, 0, 0, 0, 3, 4], 1, []),

    'Bbsus2': _ChordInfo([-1, 1, 3, 3, 1, 1], [0, 1, 3, 4, 1, 1], 1, [1]),
    'Ebsus2': _ChordInfo([-1, -1, 1, 3, 4, 1], [0, 0, 1, 3, 4, 1], 1, []),
    'Absus2': _ChordInfo([4, 6, 6, 3, 4, 4], [1, 3, 4, 1, 1, 1], 3, []),
    'F#sus2': _ChordInfo([2, 4, 4, 1, 2, 2], [1, 3, 4, 1, 1, 1], 1, []),
    'C#sus2': _ChordInfo([-1, 4, 6, 6, 4, 4], [0, 1, 3, 4, 1, 1], 4, [4]),

    // ── Suspended 4 ──
    'Asus4': _ChordInfo([0, 0, 2, 2, 3, 0], [0, 0, 1, 2, 3, 0], 1, []),
    'Bsus4': _ChordInfo([-1, 2, 4, 4, 5, 2], [0, 1, 2, 3, 4, 1], 2, [2]),
    'Csus4': _ChordInfo([-1, 3, 5, 5, 6, 3], [0, 1, 2, 3, 4, 1], 3, [3]),
    'Dsus4': _ChordInfo([-1, -1, 0, 2, 3, 3], [0, 0, 0, 1, 2, 3], 1, []),
    'Esus4': _ChordInfo([0, 2, 2, 2, 0, 0], [0, 2, 3, 4, 0, 0], 1, []),
    'Fsus4': _ChordInfo([1, 1, 3, 3, 4, 1], [1, 1, 2, 3, 4, 1], 1, [1]),
    'Gsus4': _ChordInfo([3, 5, 5, 5, 3, 3], [1, 2, 3, 4, 1, 1], 3, [3]),

    // ── 7sus4 ──
    'A7sus4': _ChordInfo([-1, 0, 2, 0, 3, 0], [0, 0, 1, 0, 3, 0], 1, []),
    'B7sus4': _ChordInfo([-1, 2, 4, 2, 5, 2], [0, 1, 3, 1, 4, 1], 2, [2]),
    'C7sus4': _ChordInfo([-1, 3, 5, 3, 6, 3], [0, 1, 3, 1, 4, 1], 3, [3]),
    'D7sus4': _ChordInfo([-1, -1, 0, 2, 1, 3], [0, 0, 0, 2, 1, 3], 1, []),
    'E7sus4': _ChordInfo([0, 2, 0, 2, 0, 0], [0, 2, 0, 3, 0, 0], 1, []),
    'F7sus4': _ChordInfo([1, 1, 3, 1, 4, 1], [1, 1, 3, 1, 4, 1], 1, [1]),
    'G7sus4': _ChordInfo([3, 5, 3, 5, 3, 3], [1, 3, 1, 4, 1, 1], 3, [3]),

    // ── Diminished ──
    'Cdim':  _ChordInfo([-1, 3, 4, 5, 4, -1], [0, 1, 2, 4, 3, 0], 3, []),
    'Ddim':  _ChordInfo([-1, -1, 0, 1, 3, 1], [0, 0, 0, 1, 3, 2], 1, []),
    'Edim':  _ChordInfo([-1, -1, 2, 3, 2, 0], [0, 0, 1, 3, 2, 0], 1, []),
    'Fdim':  _ChordInfo([-1, -1, 3, 4, 3, 1], [0, 0, 2, 4, 3, 1], 1, []),
    'Gdim':  _ChordInfo([-1, -1, 5, 6, 5, 3], [0, 0, 2, 4, 3, 1], 3, []),
    'Adim':  _ChordInfo([-1, 0, 1, 2, 1, -1], [0, 0, 1, 3, 2, 0], 1, []),
    'Bdim':  _ChordInfo([-1, 2, 3, 4, 3, -1], [0, 1, 2, 4, 3, 0], 2, []),
    'C#dim': _ChordInfo([-1, -1, 2, 3, 2, 0], [0, 0, 1, 3, 2, 0], 1, []),
    'Dbdim': _ChordInfo([-1, -1, 2, 3, 2, 0], [0, 0, 1, 3, 2, 0], 1, []),
    'D#dim': _ChordInfo([-1, -1, 1, 2, 1, -1], [0, 0, 1, 3, 2, 0], 1, []),
    'Ebdim': _ChordInfo([-1, -1, 1, 2, 1, -1], [0, 0, 1, 3, 2, 0], 1, []),
    'F#dim': _ChordInfo([-1, -1, 4, 5, 4, 2], [0, 0, 2, 4, 3, 1], 2, []),
    'Gbdim': _ChordInfo([-1, -1, 4, 5, 4, 2], [0, 0, 2, 4, 3, 1], 2, []),
    'G#dim': _ChordInfo([-1, -1, 0, 1, 0, -1], [0, 0, 0, 1, 0, 0], 1, []),
    'Abdim': _ChordInfo([-1, -1, 0, 1, 0, -1], [0, 0, 0, 1, 0, 0], 1, []),
    'A#dim': _ChordInfo([-1, 1, 2, 3, 2, -1], [0, 1, 2, 4, 3, 0], 1, []),
    'Bbdim': _ChordInfo([-1, 1, 2, 3, 2, -1], [0, 1, 2, 4, 3, 0], 1, []),

    // ── Augmented ──
    'Caug':  _ChordInfo([-1, 3, 2, 1, 1, 0], [0, 4, 3, 1, 2, 0], 1, []),
    'Daug':  _ChordInfo([-1, -1, 0, 3, 3, 2], [0, 0, 0, 2, 3, 1], 1, []),
    'Eaug':  _ChordInfo([0, 3, 2, 1, 1, 0], [0, 4, 3, 1, 2, 0], 1, []),
    'Faug':  _ChordInfo([-1, -1, 3, 2, 2, 1], [0, 0, 4, 2, 3, 1], 1, []),
    'Gaug':  _ChordInfo([3, 2, 1, 0, 0, 3], [3, 2, 1, 0, 0, 4], 1, []),
    'Aaug':  _ChordInfo([-1, 0, 3, 2, 2, 1], [0, 0, 4, 2, 3, 1], 1, []),
    'Baug':  _ChordInfo([-1, 2, 1, 0, 0, 3], [0, 3, 2, 0, 0, 4], 1, []),
    'C#aug': _ChordInfo([-1, 4, 3, 2, 2, 1], [0, 4, 3, 1, 2, 0], 1, []),
    'Dbaug': _ChordInfo([-1, 4, 3, 2, 2, 1], [0, 4, 3, 1, 2, 0], 1, []),
    'D#aug': _ChordInfo([-1, -1, 1, 0, 0, 3], [0, 0, 1, 0, 0, 4], 1, []),
    'Ebaug': _ChordInfo([-1, -1, 1, 0, 0, 3], [0, 0, 1, 0, 0, 4], 1, []),
    'F#aug': _ChordInfo([-1, -1, 4, 3, 3, 2], [0, 0, 4, 2, 3, 1], 2, []),
    'Gbaug': _ChordInfo([-1, -1, 4, 3, 3, 2], [0, 0, 4, 2, 3, 1], 2, []),
    'G#aug': _ChordInfo([-1, -1, 2, 1, 1, 0], [0, 0, 3, 1, 2, 0], 1, []),
    'Abaug': _ChordInfo([-1, -1, 2, 1, 1, 0], [0, 0, 3, 1, 2, 0], 1, []),
    'A#aug': _ChordInfo([-1, 1, 0, 3, 3, 2], [0, 1, 0, 3, 4, 2], 1, []),
    'Bbaug': _ChordInfo([-1, 1, 0, 3, 3, 2], [0, 1, 0, 3, 4, 2], 1, []),

    // ── Add9 ──
    'Cadd9': _ChordInfo([0, 3, 2, 0, 3, 0], [0, 2, 1, 0, 3, 0], 1, []),
    'Dadd9': _ChordInfo([-1, -1, 0, 2, 3, 0], [0, 0, 0, 1, 3, 0], 1, []),
    'Eadd9': _ChordInfo([0, 2, 2, 1, 0, 2], [0, 2, 3, 1, 0, 4], 1, []),
    'Gadd9': _ChordInfo([3, 0, 0, 2, 0, 3], [2, 0, 0, 1, 0, 3], 1, []),
    'Aadd9': _ChordInfo([-1, 0, 2, 2, 2, 0], [0, 0, 1, 2, 3, 0], 1, []),
    'Fadd9': _ChordInfo([-1, -1, 3, 2, 1, 3], [0, 0, 2, 1, 0, 3], 1, []),

    // ── 6th Chords ──
    'C6': _ChordInfo([0, 3, 2, 2, 1, 0], [0, 4, 2, 3, 1, 0], 1, []),
    'D6': _ChordInfo([-1, -1, 0, 2, 0, 2], [0, 0, 0, 2, 0, 3], 1, []),
    'E6': _ChordInfo([0, 2, 2, 1, 2, 0], [0, 2, 3, 1, 4, 0], 1, []),
    'F6': _ChordInfo([1, 3, 3, 2, 3, 1], [1, 2, 3, 1, 4, 1], 1, [1]),
    'G6': _ChordInfo([3, 2, 0, 0, 0, 0], [2, 1, 0, 0, 0, 0], 1, []),
    'A6': _ChordInfo([-1, 0, 2, 2, 2, 2], [0, 0, 1, 2, 3, 4], 1, []),
    'Bb6': _ChordInfo([-1, 1, 3, 3, 3, 3], [0, 1, 2, 3, 3, 4], 1, []),

    // ── Minor 6th ──
    'Am6': _ChordInfo([0, 0, 2, 2, 1, 2], [0, 0, 2, 3, 1, 4], 1, []),
    'Dm6': _ChordInfo([-1, -1, 0, 2, 0, 1], [0, 0, 0, 2, 0, 1], 1, []),
    'Em6': _ChordInfo([0, 2, 2, 0, 2, 0], [0, 2, 3, 0, 4, 0], 1, []),

    // ── Dominant 9th ──
    'C9':  _ChordInfo([0, 3, 2, 3, 3, 0], [0, 2, 1, 3, 4, 0], 1, []),
    'D9':  _ChordInfo([-1, -1, 0, 2, 1, 0], [0, 0, 0, 2, 1, 0], 1, []),
    'E9':  _ChordInfo([0, 2, 0, 1, 0, 2], [0, 2, 0, 1, 0, 3], 1, []),
    'G9':  _ChordInfo([3, 0, 0, 2, 0, 1], [3, 0, 0, 2, 0, 1], 1, []),
    'A9':  _ChordInfo([-1, 0, 2, 0, 2, 3], [0, 0, 1, 0, 2, 4], 1, []),
    'Ab9': _ChordInfo([4, 6, 4, 5, 4, 6], [1, 3, 1, 2, 1, 4], 4, [4]),
    'Bb9': _ChordInfo([-1, 1, 0, 1, 1, 1], [0, 1, 0, 2, 3, 4], 1, []),

    // ── Add4 ──
    'Badd4':  _ChordInfo([-1, 2, 4, 4, 4, 4], [0, 1, 2, 3, 3, 4], 2, []),
    'Cadd4':  _ChordInfo([0, 3, 2, 0, 1, 1], [0, 3, 2, 0, 1, 1], 1, []),
    'Dadd4':  _ChordInfo([-1, -1, 0, 2, 3, 3], [0, 0, 0, 1, 2, 3], 1, []),
    'Eadd4':  _ChordInfo([0, 2, 2, 1, 0, 0], [0, 2, 3, 1, 0, 0], 1, []),
    'Gadd4':  _ChordInfo([3, 2, 0, 0, 1, 3], [2, 1, 0, 0, 1, 4], 1, []),
  };
}

class _ChordInfo {
  final List<int> frets;    // -1=muted, 0=open, 1+=fret number
  final List<int> fingers;  // finger numbers (0=none)
  final int baseFret;       // starting fret (1 = nut)
  final List<int> barres;   // barre fret numbers

  const _ChordInfo(this.frets, this.fingers, this.baseFret, this.barres);
}

class _ChordDiagramPainter extends CustomPainter {
  final List<int> frets;
  final List<int> fingers;
  final int baseFret;
  final List<int> barres;
  final String chordName;
  final bool isDark;

  _ChordDiagramPainter({
    required this.frets, required this.fingers, required this.baseFret,
    required this.barres, required this.chordName, required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final numStrings = 6;
    final numFrets = 4;
    final topMargin = size.height * 0.28;
    final bottomMargin = size.height * 0.05;
    final leftMargin = size.width * 0.15;
    final rightMargin = size.width * 0.1;
    final fretboardWidth = size.width - leftMargin - rightMargin;
    final fretboardHeight = size.height - topMargin - bottomMargin;
    final stringSpacing = fretboardWidth / (numStrings - 1);
    final fretSpacing = fretboardHeight / numFrets;

    final lineColor = isDark ? Colors.white70 : Colors.black87;
    final dotColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;

    // Chord name
    final namePainter = TextPainter(
      text: TextSpan(text: chordName, style: TextStyle(
        fontSize: size.height * 0.12, fontWeight: FontWeight.bold, color: textColor,
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    namePainter.paint(canvas, Offset((size.width - namePainter.width) / 2, 0));

    // Nut or base fret indicator
    if (baseFret == 1) {
      canvas.drawRect(
        Rect.fromLTWH(leftMargin - 1, topMargin - 3, fretboardWidth + 2, 4),
        Paint()..color = lineColor..style = PaintingStyle.fill,
      );
    } else {
      final fretPainter = TextPainter(
        text: TextSpan(text: '$baseFret', style: TextStyle(
          fontSize: size.height * 0.08, color: textColor,
        )),
        textDirection: TextDirection.ltr,
      )..layout();
      fretPainter.paint(canvas, Offset(2, topMargin + 2));
    }

    // Fret lines
    final linePaint = Paint()..color = lineColor.withValues(alpha: 0.4)..strokeWidth = 1;
    for (int f = 0; f <= numFrets; f++) {
      final y = topMargin + f * fretSpacing;
      canvas.drawLine(Offset(leftMargin, y), Offset(leftMargin + fretboardWidth, y), linePaint);
    }

    // String lines
    for (int s = 0; s < numStrings; s++) {
      final x = leftMargin + s * stringSpacing;
      canvas.drawLine(Offset(x, topMargin), Offset(x, topMargin + fretboardHeight), linePaint);
    }

    // Barres
    for (final barre in barres) {
      final fretY = topMargin + (barre - baseFret + 0.5) * fretSpacing;
      int minString = numStrings - 1, maxString = 0;
      for (int s = 0; s < numStrings; s++) {
        if (frets[s] == barre) {
          if (s < minString) minString = s;
          if (s > maxString) maxString = s;
        }
      }
      if (minString < maxString) {
        final x1 = leftMargin + minString * stringSpacing;
        final x2 = leftMargin + maxString * stringSpacing;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(x1 - 4, fretY - 5, x2 + 4, fretY + 5), const Radius.circular(5)),
          Paint()..color = dotColor,
        );
      }
    }

    // Dots and markers
    final dotRadius = stringSpacing * 0.3;
    for (int s = 0; s < numStrings; s++) {
      final x = leftMargin + s * stringSpacing;

      if (frets[s] == -1) {
        // Muted X
        final markerY = topMargin - size.height * 0.06;
        final p = Paint()..color = lineColor..strokeWidth = 2..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(x - 5, markerY - 5), Offset(x + 5, markerY + 5), p);
        canvas.drawLine(Offset(x + 5, markerY - 5), Offset(x - 5, markerY + 5), p);
      } else if (frets[s] == 0) {
        // Open O
        final markerY = topMargin - size.height * 0.06;
        canvas.drawCircle(Offset(x, markerY), 5,
          Paint()..color = lineColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
      } else {
        // Finger dot
        final fretY = topMargin + (frets[s] - baseFret + 0.5) * fretSpacing;
        // Skip if part of barre (already drawn)
        if (barres.contains(frets[s]) && frets.where((f) => f == frets[s]).length > 2) {
          continue;
        }
        canvas.drawCircle(Offset(x, fretY), dotRadius, Paint()..color = dotColor);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChordDiagramPainter old) =>
      old.chordName != chordName || old.isDark != isDark;
}

import 'package:flutter/material.dart';

/// Guitar chord diagram widget — draws fretboard with finger positions.
class ChordDiagram extends StatelessWidget {
  final String chordName;
  final double size;

  const ChordDiagram({super.key, required this.chordName, this.size = 160});

  @override
  Widget build(BuildContext context) {
    final data = _chordData[_normalizeChord(chordName)];
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

  static String _normalizeChord(String name) {
    // Strip bass note (slash chord)
    final slashIdx = name.indexOf('/');
    final base = slashIdx > 0 ? name.substring(0, slashIdx) : name;
    return base.trim();
  }

  // Chord data: frets = [E,A,D,G,B,e], -1 = muted, 0 = open
  static final Map<String, _ChordInfo> _chordData = {
    // Major
    'C':  _ChordInfo([0, 3, 2, 0, 1, 0], [0, 3, 2, 0, 1, 0], 1, []),
    'D':  _ChordInfo([-1, -1, 0, 2, 3, 2], [0, 0, 0, 1, 3, 2], 1, []),
    'E':  _ChordInfo([0, 2, 2, 1, 0, 0], [0, 2, 3, 1, 0, 0], 1, []),
    'F':  _ChordInfo([1, 1, 2, 3, 3, 1], [1, 1, 2, 3, 4, 1], 1, [1]),
    'G':  _ChordInfo([3, 2, 0, 0, 0, 3], [2, 1, 0, 0, 0, 3], 1, []),
    'A':  _ChordInfo([0, 0, 2, 2, 2, 0], [0, 0, 1, 2, 3, 0], 1, []),
    'B':  _ChordInfo([-1, 2, 4, 4, 4, 2], [0, 1, 2, 3, 4, 1], 2, [2]),
    // Minor
    'Am': _ChordInfo([0, 0, 2, 2, 1, 0], [0, 0, 2, 3, 1, 0], 1, []),
    'Bm': _ChordInfo([-1, 2, 4, 4, 3, 2], [0, 1, 3, 4, 2, 1], 2, [2]),
    'Cm': _ChordInfo([-1, 3, 5, 5, 4, 3], [0, 1, 3, 4, 2, 1], 3, [3]),
    'Dm': _ChordInfo([-1, -1, 0, 2, 3, 1], [0, 0, 0, 2, 3, 1], 1, []),
    'Em': _ChordInfo([0, 2, 2, 0, 0, 0], [0, 2, 3, 0, 0, 0], 1, []),
    'Fm': _ChordInfo([1, 1, 3, 3, 2, 1], [1, 1, 3, 4, 2, 1], 1, [1]),
    'Gm': _ChordInfo([3, 1, 0, 0, 3, 3], [2, 1, 0, 0, 3, 4], 1, []),
    // 7th
    'A7': _ChordInfo([0, 0, 2, 0, 2, 0], [0, 0, 2, 0, 3, 0], 1, []),
    'B7': _ChordInfo([-1, 2, 1, 2, 0, 2], [0, 2, 1, 3, 0, 4], 1, []),
    'C7': _ChordInfo([0, 3, 2, 3, 1, 0], [0, 3, 2, 4, 1, 0], 1, []),
    'D7': _ChordInfo([-1, -1, 0, 2, 1, 2], [0, 0, 0, 2, 1, 3], 1, []),
    'E7': _ChordInfo([0, 2, 0, 1, 0, 0], [0, 2, 0, 1, 0, 0], 1, []),
    'G7': _ChordInfo([3, 2, 0, 0, 0, 1], [3, 2, 0, 0, 0, 1], 1, []),
    // Minor 7
    'Am7': _ChordInfo([0, 0, 2, 0, 1, 0], [0, 0, 2, 0, 1, 0], 1, []),
    'Bm7': _ChordInfo([-1, 2, 0, 2, 0, 2], [0, 2, 0, 3, 0, 4], 1, []),
    'Dm7': _ChordInfo([-1, -1, 0, 2, 1, 1], [0, 0, 0, 2, 1, 1], 1, []),
    'Em7': _ChordInfo([0, 2, 0, 0, 0, 0], [0, 1, 0, 0, 0, 0], 1, []),
    // Suspended
    'Asus4': _ChordInfo([0, 0, 2, 2, 3, 0], [0, 0, 1, 2, 3, 0], 1, []),
    'Dsus4': _ChordInfo([-1, -1, 0, 2, 3, 3], [0, 0, 0, 1, 2, 3], 1, []),
    'Esus4': _ChordInfo([0, 2, 2, 2, 0, 0], [0, 2, 3, 4, 0, 0], 1, []),
    // Sharp/Flat equivalents
    'C#': _ChordInfo([-1, 4, 6, 6, 6, 4], [0, 1, 2, 3, 4, 1], 4, [4]),
    'C#m': _ChordInfo([-1, 4, 6, 6, 5, 4], [0, 1, 3, 4, 2, 1], 4, [4]),
    'D#': _ChordInfo([-1, -1, 1, 3, 4, 3], [0, 0, 1, 2, 4, 3], 1, []),
    'D#m': _ChordInfo([-1, -1, 1, 3, 4, 2], [0, 0, 1, 3, 4, 2], 1, []),
    'F#': _ChordInfo([2, 4, 4, 3, 2, 2], [1, 3, 4, 2, 1, 1], 2, [2]),
    'F#m': _ChordInfo([2, 4, 4, 2, 2, 2], [1, 3, 4, 1, 1, 1], 2, [2]),
    'G#': _ChordInfo([4, 6, 6, 5, 4, 4], [1, 3, 4, 2, 1, 1], 4, [4]),
    'G#m': _ChordInfo([4, 6, 6, 4, 4, 4], [1, 3, 4, 1, 1, 1], 4, [4]),
    'A#': _ChordInfo([-1, 1, 3, 3, 3, 1], [0, 1, 2, 3, 4, 1], 1, [1]),
    'A#m': _ChordInfo([-1, 1, 3, 3, 2, 1], [0, 1, 3, 4, 2, 1], 1, [1]),
    'Bb': _ChordInfo([-1, 1, 3, 3, 3, 1], [0, 1, 2, 3, 4, 1], 1, [1]),
    'Bbm': _ChordInfo([-1, 1, 3, 3, 2, 1], [0, 1, 3, 4, 2, 1], 1, [1]),
    'Eb': _ChordInfo([-1, -1, 1, 3, 4, 3], [0, 0, 1, 2, 4, 3], 1, []),
    'Ebm': _ChordInfo([-1, -1, 1, 3, 4, 2], [0, 0, 1, 3, 4, 2], 1, []),
    'Ab': _ChordInfo([4, 6, 6, 5, 4, 4], [1, 3, 4, 2, 1, 1], 4, [4]),
    'Abm': _ChordInfo([4, 6, 6, 4, 4, 4], [1, 3, 4, 1, 1, 1], 4, [4]),
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

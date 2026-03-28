class ChordUtils {
  static const chromaticSharps = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const chromaticFlats = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  /// Chord templates for detection (12-bin chroma vectors)
  static const Map<String, List<int>> chordTemplates = {
    'maj': [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0],
    'm':   [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0],
    '7':   [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0],
    'm7':  [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0],
    'maj7':[1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1],
    'dim': [1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0],
    'aug': [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0],
    'sus2':[1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0],
    'sus4':[1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0],
  };

  /// Rotate a template by N semitones for a given root
  static List<int> rotateTemplate(List<int> template, int semitones) {
    final len = template.length;
    return List.generate(len, (i) => template[(i - semitones + len) % len]);
  }

  /// Format semitone offset as display string
  static String formatTranspose(int semitones) {
    if (semitones == 0) return '0';
    return semitones > 0 ? '+$semitones' : '$semitones';
  }
}

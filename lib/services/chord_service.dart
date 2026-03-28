import '../models/chord.dart';
import '../models/song.dart';
import '../models/song_section.dart';

class ChordService {
  static const _sharps = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const _flats = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

  static final _chordRegex = RegExp(
    r'^([A-G][#b]?)(m(?:aj)?|dim|aug|sus[24]?|add)?(\d+)?(/([A-G][#b]?))?$',
  );

  static Chord? parseChord(String symbol) {
    final match = _chordRegex.firstMatch(symbol.trim());
    if (match == null) return null;

    final root = match.group(1)!;
    final qualityPart = (match.group(2) ?? '') + (match.group(3) ?? '');
    final bass = match.group(5);

    return Chord(root: root, quality: qualityPart, bassNote: bass);
  }

  static int _noteIndex(String note) {
    var idx = _sharps.indexOf(note);
    if (idx >= 0) return idx;
    idx = _flats.indexOf(note);
    return idx;
  }

  static bool _usesFlats(String note) => _flats.contains(note) && !_sharps.contains(note);

  static String _transposeNote(String note, int semitones) {
    final idx = _noteIndex(note);
    if (idx < 0) return note;
    final newIdx = (idx + semitones) % 12;
    final useFlats = _usesFlats(note);
    return useFlats ? _flats[newIdx] : _sharps[newIdx];
  }

  static Chord transposeChord(Chord chord, int semitones) {
    final newRoot = _transposeNote(chord.root, semitones);
    final newBass =
        chord.bassNote != null ? _transposeNote(chord.bassNote!, semitones) : null;
    return chord.copyWith(root: newRoot, bassNote: newBass);
  }

  static Song transposeSong(Song song, int semitones) {
    final normalized = ((semitones % 12) + 12) % 12;
    if (normalized == 0) return song;

    final newSections = song.sections.map((section) {
      final newLines = section.lines.map((line) {
        final newChords = line.chords
            .map((chord) => transposeChord(chord, normalized))
            .toList();
        return SongLine(chords: newChords, lyrics: line.lyrics);
      }).toList();
      return SongSection(type: section.type, label: section.label, lines: newLines);
    }).toList();

    return Song(
      id: song.id,
      title: song.title,
      artist: song.artist,
      url: song.url,
      sections: newSections,
    );
  }
}

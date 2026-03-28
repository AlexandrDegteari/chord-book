import 'chord.dart';

class SongLine {
  final List<Chord> chords;
  final String lyrics;

  const SongLine({
    this.chords = const [],
    this.lyrics = '',
  });

  factory SongLine.fromJson(Map<String, dynamic> json) {
    return SongLine(
      chords: (json['chords'] as List<dynamic>?)
              ?.map((c) => Chord.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      lyrics: json['lyrics'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'chords': chords.map((c) => c.toJson()).toList(),
        'lyrics': lyrics,
      };
}

enum SectionType {
  verse,
  chorus,
  bridge,
  intro,
  outro,
  solo,
  preChorus,
  interlude,
  unknown;

  static SectionType fromString(String s) {
    final lower = s.toLowerCase().trim();
    if (lower.contains('chorus') || lower.contains('припев') || lower.contains('ref')) {
      return SectionType.chorus;
    }
    if (lower.contains('verse') || lower.contains('куплет') || lower.contains('couplet')) {
      return SectionType.verse;
    }
    if (lower.contains('bridge') || lower.contains('мост') || lower.contains('бридж')) {
      return SectionType.bridge;
    }
    if (lower.contains('intro') || lower.contains('вступ')) return SectionType.intro;
    if (lower.contains('outro') || lower.contains('конц')) return SectionType.outro;
    if (lower.contains('solo') || lower.contains('соло')) return SectionType.solo;
    if (lower.contains('pre-chorus') || lower.contains('пре')) return SectionType.preChorus;
    if (lower.contains('interlude')) return SectionType.interlude;
    return SectionType.unknown;
  }
}

class SongSection {
  final SectionType type;
  final String label; // Original label text
  final List<SongLine> lines;

  const SongSection({
    this.type = SectionType.unknown,
    this.label = '',
    this.lines = const [],
  });

  factory SongSection.fromJson(Map<String, dynamic> json) {
    return SongSection(
      type: SectionType.fromString(json['label'] as String? ?? ''),
      label: json['label'] as String? ?? '',
      lines: (json['lines'] as List<dynamic>?)
              ?.map((l) => SongLine.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}

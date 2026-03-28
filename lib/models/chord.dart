class Chord {
  final String root; // C, C#, Db, etc.
  final String quality; // m, 7, maj7, dim, aug, sus2, sus4, etc.
  final String? bassNote; // For slash chords: C/E → bassNote = E
  final int position; // Character position in lyrics line

  const Chord({
    required this.root,
    this.quality = '',
    this.bassNote,
    this.position = 0,
  });

  String get display {
    final bass = bassNote != null ? '/$bassNote' : '';
    return '$root$quality$bass';
  }

  Chord copyWith({
    String? root,
    String? quality,
    String? bassNote,
    int? position,
  }) {
    return Chord(
      root: root ?? this.root,
      quality: quality ?? this.quality,
      bassNote: bassNote ?? this.bassNote,
      position: position ?? this.position,
    );
  }

  factory Chord.fromJson(Map<String, dynamic> json) {
    return Chord(
      root: json['root'] as String,
      quality: json['quality'] as String? ?? '',
      bassNote: json['bassNote'] as String?,
      position: json['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'root': root,
        'quality': quality,
        'bassNote': bassNote,
        'position': position,
      };
}

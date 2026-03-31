class TimeSignature {
  final int beatsPerMeasure;
  final int noteValue;

  const TimeSignature({required this.beatsPerMeasure, required this.noteValue});

  String get display => '$beatsPerMeasure/$noteValue';

  static const presets = [
    TimeSignature(beatsPerMeasure: 2, noteValue: 4),
    TimeSignature(beatsPerMeasure: 3, noteValue: 4),
    TimeSignature(beatsPerMeasure: 4, noteValue: 4),
    TimeSignature(beatsPerMeasure: 5, noteValue: 4),
    TimeSignature(beatsPerMeasure: 6, noteValue: 8),
    TimeSignature(beatsPerMeasure: 7, noteValue: 8),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSignature &&
          beatsPerMeasure == other.beatsPerMeasure &&
          noteValue == other.noteValue;

  @override
  int get hashCode => Object.hash(beatsPerMeasure, noteValue);
}

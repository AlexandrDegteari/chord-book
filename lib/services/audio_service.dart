import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import '../config/app_config.dart';

class ChordDetectionResult {
  final String chord; // e.g. "Am", "C", "G7"
  final double confidence;
  final List<double> chroma; // 12-bin chroma vector

  const ChordDetectionResult({
    required this.chord,
    required this.confidence,
    this.chroma = const [],
  });

  static const none = ChordDetectionResult(chord: '', confidence: 0);
}

class AudioChordDetector {
  static const _noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  // Chord templates: 12-bin binary vectors (starting from C)
  static const Map<String, List<int>> _chordTypes = {
    '': [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0], // major
    'm': [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0], // minor
    '7': [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0], // dominant 7
    'm7': [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0], // minor 7
    'maj7': [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1], // major 7
    'dim': [1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0], // diminished
    'aug': [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0], // augmented
    'sus2': [1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0], // sus2
    'sus4': [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0], // sus4
  };

  final int _sampleRate;
  final int _fftSize;
  late final FFT _fft;
  late final Float64List _window;

  // Smoothing buffer
  final List<String> _recentChords = [];
  static const _smoothingSize = 4;

  AudioChordDetector({
    int sampleRate = AppConfig.sampleRate,
    int fftSize = AppConfig.fftSize,
  })  : _sampleRate = sampleRate,
        _fftSize = fftSize {
    _fft = FFT(_fftSize);
    _window = Float64List(_fftSize);
    // Hann window
    for (int i = 0; i < _fftSize; i++) {
      _window[i] = 0.5 * (1 - cos(2 * pi * i / (_fftSize - 1)));
    }
  }

  /// Process a buffer of audio samples and detect the chord
  ChordDetectionResult detect(List<double> samples) {
    if (samples.length < _fftSize) return ChordDetectionResult.none;

    // Take the last _fftSize samples
    final buffer = Float64List(_fftSize);
    final offset = samples.length - _fftSize;
    for (int i = 0; i < _fftSize; i++) {
      buffer[i] = samples[offset + i] * _window[i];
    }

    // Run FFT
    final spectrum = _fft.realFft(buffer);
    final magnitudes = spectrum.discardConjugates().magnitudes();

    // Compute chroma vector
    final chroma = _computeChroma(magnitudes);

    // Match against templates
    return _matchChord(chroma);
  }

  /// Compute 12-bin chroma vector from FFT magnitudes
  Float64List _computeChroma(Float64List magnitudes) {
    final chroma = Float64List(12);
    final binCount = magnitudes.length;

    for (int bin = 1; bin < binCount; bin++) {
      final freq = bin * _sampleRate / _fftSize;
      if (freq < 60 || freq > 2000) continue; // Guitar range roughly

      // Map frequency to pitch class
      final midiNote = 12 * log(freq / 440) / ln2 + 69;
      final pitchClass = midiNote.round() % 12;

      if (pitchClass >= 0 && pitchClass < 12) {
        chroma[pitchClass] += magnitudes[bin] * magnitudes[bin]; // Energy
      }
    }

    // Normalize
    final maxVal = chroma.reduce(max);
    if (maxVal > 0) {
      for (int i = 0; i < 12; i++) {
        chroma[i] /= maxVal;
      }
    }

    return chroma;
  }

  /// Match chroma vector against chord templates using cosine similarity
  ChordDetectionResult _matchChord(Float64List chroma) {
    String bestChord = '';
    double bestScore = 0;

    for (final root in Iterable<int>.generate(12)) {
      for (final entry in _chordTypes.entries) {
        final template = _rotateTemplate(entry.value, root);
        final score = _cosineSimilarity(chroma, template);

        if (score > bestScore) {
          bestScore = score;
          bestChord = '${_noteNames[root]}${entry.key}';
        }
      }
    }

    // Apply temporal smoothing
    final smoothed = _applySmoothing(bestChord, bestScore);

    return ChordDetectionResult(
      chord: smoothed,
      confidence: bestScore,
      chroma: chroma.toList(),
    );
  }

  List<double> _rotateTemplate(List<int> template, int semitones) {
    final len = template.length;
    return List<double>.generate(
        len, (i) => template[(i - semitones + len) % len].toDouble());
  }

  double _cosineSimilarity(Float64List a, List<double> b) {
    double dotProduct = 0, normA = 0, normB = 0;
    for (int i = 0; i < 12; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = sqrt(normA) * sqrt(normB);
    return denom > 0 ? dotProduct / denom : 0;
  }

  /// Majority vote over recent detections
  String _applySmoothing(String chord, double confidence) {
    if (confidence < AppConfig.chordConfidenceThreshold) {
      return _recentChords.isNotEmpty ? _recentChords.last : '';
    }

    _recentChords.add(chord);
    if (_recentChords.length > _smoothingSize) {
      _recentChords.removeAt(0);
    }

    // Count occurrences
    final counts = <String, int>{};
    for (final c in _recentChords) {
      counts[c] = (counts[c] ?? 0) + 1;
    }

    // Return most common
    String majority = chord;
    int maxCount = 0;
    counts.forEach((c, count) {
      if (count > maxCount) {
        maxCount = count;
        majority = c;
      }
    });

    return majority;
  }

  void reset() {
    _recentChords.clear();
  }
}

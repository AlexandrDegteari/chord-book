import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:typed_data';
import 'package:fftea/fftea.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

class AudioState {
  final bool isListening;
  final String detectedNote; // Root note for chord matching: C, C#, D, etc.
  final String detectedChord; // Full chord name: Am, C, G7, etc.
  final double frequency;
  final String? error;

  const AudioState({
    this.isListening = false,
    this.detectedNote = '',
    this.detectedChord = '',
    this.frequency = 0,
    this.error,
  });

  AudioState copyWith({
    bool? isListening,
    String? detectedNote,
    String? detectedChord,
    double? frequency,
    String? error,
  }) {
    return AudioState(
      isListening: isListening ?? this.isListening,
      detectedNote: detectedNote ?? this.detectedNote,
      detectedChord: detectedChord ?? this.detectedChord,
      frequency: frequency ?? this.frequency,
      error: error,
    );
  }
}

final audioProvider =
    NotifierProvider<AudioNotifier, AudioState>(AudioNotifier.new);

class AudioNotifier extends Notifier<AudioState> {
  final _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _subscription;

  static const _sampleRate = 44100;
  static const _fftSize = 4096;
  late final FFT _fft;
  late final Float64List _window;

  // Chord templates: 12-bin binary vectors (starting from C)
  static const _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static const Map<String, List<int>> _chordTypes = {
    '':     [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0], // major
    'm':    [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0], // minor
    '7':    [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0], // dominant 7
    'm7':   [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0], // minor 7
    'maj7': [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1], // major 7
    'sus4': [1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0], // sus4
  };

  // Temporal smoothing
  final List<String> _recentChords = [];
  static const _smoothingSize = 3;

  @override
  AudioState build() {
    _fft = FFT(_fftSize);
    _window = Float64List(_fftSize);
    for (int i = 0; i < _fftSize; i++) {
      _window[i] = 0.5 * (1 - cos(2 * pi * i / (_fftSize - 1)));
    }
    return const AudioState();
  }

  Future<void> startListening() async {
    if (state.isListening) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(error: 'Microphone permission denied', isListening: false);
      return;
    }

    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );

      _recentChords.clear();
      _subscription = stream.listen(_processAudioData);
      state = state.copyWith(isListening: true, error: null);
    } catch (e) {
      dev.log('[AudioProvider] Failed: $e');
      state = state.copyWith(error: 'Failed: $e', isListening: false);
    }
  }

  void _processAudioData(Uint8List data) {
    // Convert PCM16 to float
    final floatData = Float64List(data.length ~/ 2);
    for (int i = 0; i < data.length - 1; i += 2) {
      final int sample = data[i] | (data[i + 1] << 8);
      final int signedSample = sample > 32767 ? sample - 65536 : sample;
      floatData[i ~/ 2] = signedSample / 32768.0;
    }
    if (floatData.length < _fftSize) return;

    // Check RMS — skip if too quiet
    double rms = 0;
    for (int i = 0; i < _fftSize; i++) {
      rms += floatData[i] * floatData[i];
    }
    rms = sqrt(rms / _fftSize);
    if (rms < 0.01) return;

    // Apply window and run FFT
    final windowed = Float64List(_fftSize);
    for (int i = 0; i < _fftSize; i++) {
      windowed[i] = floatData[i] * _window[i];
    }

    final spectrum = _fft.realFft(windowed);
    final magnitudes = spectrum.discardConjugates().magnitudes();

    // Compute 12-bin chroma vector
    final chroma = Float64List(12);
    for (int bin = 1; bin < magnitudes.length; bin++) {
      final freq = bin * _sampleRate / _fftSize;
      if (freq < 60 || freq > 2000) continue;
      final midiNote = 12 * log(freq / 440) / ln2 + 69;
      final pitchClass = midiNote.round() % 12;
      if (pitchClass >= 0 && pitchClass < 12) {
        chroma[pitchClass] += magnitudes[bin] * magnitudes[bin];
      }
    }

    // Normalize chroma
    final maxVal = chroma.reduce(max);
    if (maxVal <= 0) return;
    for (int i = 0; i < 12; i++) {
      chroma[i] /= maxVal;
    }

    // Match against chord templates
    String bestChord = '';
    String bestRoot = '';
    double bestScore = 0;

    for (int root = 0; root < 12; root++) {
      for (final entry in _chordTypes.entries) {
        final template = List<double>.generate(
            12, (i) => entry.value[(i - root + 12) % 12].toDouble());

        // Cosine similarity
        double dot = 0, normA = 0, normB = 0;
        for (int i = 0; i < 12; i++) {
          dot += chroma[i] * template[i];
          normA += chroma[i] * chroma[i];
          normB += template[i] * template[i];
        }
        final denom = sqrt(normA) * sqrt(normB);
        if (denom <= 0) continue;
        final score = dot / denom;

        if (score > bestScore) {
          bestScore = score;
          bestChord = '${_noteNames[root]}${entry.key}';
          bestRoot = _noteNames[root];
        }
      }
    }

    if (bestScore < 0.6) return;

    // Temporal smoothing — majority vote
    _recentChords.add(bestChord);
    if (_recentChords.length > _smoothingSize) _recentChords.removeAt(0);

    final counts = <String, int>{};
    for (final c in _recentChords) {
      counts[c] = (counts[c] ?? 0) + 1;
    }
    String majority = bestChord;
    int maxCount = 0;
    counts.forEach((c, count) {
      if (count > maxCount) {
        maxCount = count;
        majority = c;
      }
    });

    // Extract root from majority chord
    final rootMatch = RegExp(r'^[A-G]#?').firstMatch(majority);
    final finalRoot = rootMatch?.group(0) ?? bestRoot;

    state = state.copyWith(
      detectedChord: majority,
      detectedNote: finalRoot,
    );
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    await _recorder.stop();
    _recentChords.clear();
    state = const AudioState();
  }

  Future<void> toggle() async {
    if (state.isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }
}

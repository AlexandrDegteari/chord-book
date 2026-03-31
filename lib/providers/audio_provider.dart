import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

class AudioState {
  final bool isListening;
  final String detectedNote;
  final double frequency;
  final String? error;

  const AudioState({
    this.isListening = false,
    this.detectedNote = '',
    this.frequency = 0,
    this.error,
  });

  AudioState copyWith({
    bool? isListening,
    String? detectedNote,
    double? frequency,
    String? error,
  }) {
    return AudioState(
      isListening: isListening ?? this.isListening,
      detectedNote: detectedNote ?? this.detectedNote,
      frequency: frequency ?? this.frequency,
      error: error,
    );
  }
}

final audioProvider =
    NotifierProvider<AudioNotifier, AudioState>(AudioNotifier.new);

class AudioNotifier extends Notifier<AudioState> {
  final _recorder = AudioRecorder();
  final _pitchDetector = PitchDetector();
  StreamSubscription<Uint8List>? _subscription;

  final List<double> _pitchHistory = [];
  static const _historySize = 5;

  static const _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  @override
  AudioState build() {
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
          sampleRate: 44100,
          numChannels: 1,
        ),
      );

      _pitchHistory.clear();

      _subscription = stream.listen((data) {
        _processAudioData(data);
      });

      state = state.copyWith(isListening: true, error: null);
    } catch (e) {
      dev.log('[AudioProvider] Failed: $e');
      state = state.copyWith(error: 'Failed: $e', isListening: false);
    }
  }

  void _processAudioData(Uint8List data) async {
    // Convert PCM16 Uint8List to List<double>
    final floatData = <double>[];
    for (int i = 0; i < data.length - 1; i += 2) {
      final int sample = data[i] | (data[i + 1] << 8);
      final int signedSample = sample > 32767 ? sample - 65536 : sample;
      floatData.add(signedSample / 32768.0);
    }
    if (floatData.length < 2048) return;

    try {
      final result = await _pitchDetector.getPitchFromFloatBuffer(floatData);
      if (!result.pitched || result.probability < 0.9) return;

      final rawFreq = result.pitch;
      if (rawFreq < 60 || rawFreq > 1200) return;

      _pitchHistory.add(rawFreq);
      if (_pitchHistory.length > _historySize) _pitchHistory.removeAt(0);

      final freq = _medianPitch();
      if (freq <= 0) return;

      final midiNote = 12 * log(freq / 440) / ln2 + 69;
      final roundedMidi = midiNote.round();
      final noteIndex = ((roundedMidi % 12) + 12) % 12;

      state = state.copyWith(
        detectedNote: _noteNames[noteIndex],
        frequency: freq,
      );
    } catch (e) {
      dev.log('[AudioProvider] Pitch error: $e');
    }
  }

  double _medianPitch() {
    if (_pitchHistory.isEmpty) return 0;
    final sorted = List<double>.from(_pitchHistory)..sort();
    return sorted[sorted.length ~/ 2];
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    await _recorder.stop();
    _pitchHistory.clear();
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

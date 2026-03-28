import 'dart:async';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/audio_service.dart';

class AudioState {
  final bool isListening;
  final String detectedChord;
  final double confidence;
  final String? error;

  const AudioState({
    this.isListening = false,
    this.detectedChord = '',
    this.confidence = 0,
    this.error,
  });

  AudioState copyWith({
    bool? isListening,
    String? detectedChord,
    double? confidence,
    String? error,
  }) {
    return AudioState(
      isListening: isListening ?? this.isListening,
      detectedChord: detectedChord ?? this.detectedChord,
      confidence: confidence ?? this.confidence,
      error: error,
    );
  }
}

final audioProvider =
    NotifierProvider<AudioNotifier, AudioState>(AudioNotifier.new);

class AudioNotifier extends Notifier<AudioState> {
  AudioStreamer? _streamer;
  StreamSubscription<List<double>>? _subscription;
  final AudioChordDetector _detector = AudioChordDetector();
  final List<double> _sampleBuffer = [];
  static const _bufferSize = 4096;

  @override
  AudioState build() => const AudioState();

  Future<void> startListening() async {
    if (state.isListening) return;

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      state = state.copyWith(
        error: 'Microphone permission denied',
        isListening: false,
      );
      return;
    }

    try {
      _streamer = AudioStreamer();
      _sampleBuffer.clear();
      _detector.reset();

      _subscription = _streamer!.audioStream.listen(
        _onAudioData,
        onError: (Object error) {
          state = state.copyWith(
            error: 'Audio error: $error',
            isListening: false,
          );
        },
      );

      state = state.copyWith(isListening: true, error: null);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start audio: $e',
        isListening: false,
      );
    }
  }

  void _onAudioData(List<double> samples) {
    _sampleBuffer.addAll(samples);

    // Process when we have enough samples
    if (_sampleBuffer.length >= _bufferSize) {
      final result = _detector.detect(_sampleBuffer);

      if (result.chord.isNotEmpty && result.confidence > 0.5) {
        state = state.copyWith(
          detectedChord: result.chord,
          confidence: result.confidence,
        );
      }

      // Keep overlap for continuity (half buffer)
      if (_sampleBuffer.length > _bufferSize) {
        _sampleBuffer.removeRange(0, _sampleBuffer.length - _bufferSize ~/ 2);
      }
    }
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    _streamer = null;
    _sampleBuffer.clear();
    _detector.reset();

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

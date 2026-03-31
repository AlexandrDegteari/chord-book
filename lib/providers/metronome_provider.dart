import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_signature.dart';

class MetronomeState {
  final int bpm;
  final TimeSignature timeSignature;
  final bool isPlaying;
  final int currentBeat;

  const MetronomeState({
    this.bpm = 120,
    this.timeSignature = const TimeSignature(beatsPerMeasure: 4, noteValue: 4),
    this.isPlaying = false,
    this.currentBeat = 0,
  });

  MetronomeState copyWith({
    int? bpm,
    TimeSignature? timeSignature,
    bool? isPlaying,
    int? currentBeat,
  }) {
    return MetronomeState(
      bpm: bpm ?? this.bpm,
      timeSignature: timeSignature ?? this.timeSignature,
      isPlaying: isPlaying ?? this.isPlaying,
      currentBeat: currentBeat ?? this.currentBeat,
    );
  }
}

class MetronomeNotifier extends Notifier<MetronomeState> {
  final _accentPlayer = AudioPlayer();
  final _normalPlayer = AudioPlayer();
  Timer? _timer;
  final List<DateTime> _tapTimestamps = [];
  late Uint8List _accentWav;
  late Uint8List _normalWav;

  @override
  MetronomeState build() {
    _accentWav = _generateClickWav(880, 0.9);
    _normalWav = _generateClickWav(440, 0.6);
    _accentPlayer.setPlayerMode(PlayerMode.lowLatency);
    _normalPlayer.setPlayerMode(PlayerMode.lowLatency);
    _loadPrefs();
    ref.onDispose(() {
      stop();
      _accentPlayer.dispose();
      _normalPlayer.dispose();
    });
    return const MetronomeState();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bpm = prefs.getInt('metronome_bpm') ?? 120;
    final beats = prefs.getInt('metronome_ts_beats') ?? 4;
    final value = prefs.getInt('metronome_ts_value') ?? 4;
    state = state.copyWith(
      bpm: bpm,
      timeSignature: TimeSignature(beatsPerMeasure: beats, noteValue: value),
    );
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('metronome_bpm', state.bpm);
    prefs.setInt('metronome_ts_beats', state.timeSignature.beatsPerMeasure);
    prefs.setInt('metronome_ts_value', state.timeSignature.noteValue);
  }

  void toggle() {
    if (state.isPlaying) {
      stop();
    } else {
      start();
    }
  }

  void start() {
    if (state.isPlaying) return;
    state = state.copyWith(isPlaying: true, currentBeat: 0);
    _playBeat(0);
    _scheduleTimer();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isPlaying: false, currentBeat: 0);
  }

  void setBpm(int bpm) {
    bpm = bpm.clamp(20, 300);
    state = state.copyWith(bpm: bpm);
    _savePrefs();
    if (state.isPlaying) {
      _timer?.cancel();
      _scheduleTimer();
    }
  }

  void incrementBpm() => setBpm(state.bpm + 1);
  void decrementBpm() => setBpm(state.bpm - 1);

  void setTimeSignature(TimeSignature ts) {
    state = state.copyWith(timeSignature: ts, currentBeat: 0);
    _savePrefs();
    if (state.isPlaying) {
      _timer?.cancel();
      _scheduleTimer();
    }
  }

  void tapTempo() {
    final now = DateTime.now();
    if (_tapTimestamps.isNotEmpty) {
      final gap = now.difference(_tapTimestamps.last).inMilliseconds;
      if (gap > 2000) {
        _tapTimestamps.clear();
      }
    }
    _tapTimestamps.add(now);
    if (_tapTimestamps.length > 8) {
      _tapTimestamps.removeAt(0);
    }
    if (_tapTimestamps.length >= 2) {
      final intervals = <int>[];
      for (int i = 1; i < _tapTimestamps.length; i++) {
        intervals.add(
          _tapTimestamps[i].difference(_tapTimestamps[i - 1]).inMilliseconds,
        );
      }
      final avgMs = intervals.reduce((a, b) => a + b) / intervals.length;
      final bpm = (60000 / avgMs).round().clamp(20, 300);
      setBpm(bpm);
    }
  }

  void _scheduleTimer() {
    final intervalMs = (60000 / state.bpm).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      final nextBeat = (state.currentBeat + 1) % state.timeSignature.beatsPerMeasure;
      state = state.copyWith(currentBeat: nextBeat);
      _playBeat(nextBeat);
    });
  }

  void _playBeat(int beat) {
    if (beat == 0) {
      _accentPlayer.play(BytesSource(_accentWav, mimeType: 'audio/wav'));
    } else {
      _normalPlayer.play(BytesSource(_normalWav, mimeType: 'audio/wav'));
    }
  }

  /// Generate a short WAV click sound in memory.
  /// [frequency] in Hz, [volume] 0.0-1.0
  Uint8List _generateClickWav(double frequency, double volume) {
    const sampleRate = 44100;
    const durationMs = 30;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final samples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Envelope: quick attack, exponential decay
      final envelope = (1.0 - i / numSamples) * (1.0 - i / numSamples);
      final sample = sin(2 * pi * frequency * t) * volume * envelope;
      samples[i] = (sample * 32767).round().clamp(-32768, 32767);
    }

    final dataBytes = samples.buffer.asUint8List();
    final wavSize = 44 + dataBytes.length;
    final wav = ByteData(wavSize);

    // RIFF header
    wav.setUint8(0, 0x52); // R
    wav.setUint8(1, 0x49); // I
    wav.setUint8(2, 0x46); // F
    wav.setUint8(3, 0x46); // F
    wav.setUint32(4, wavSize - 8, Endian.little);
    wav.setUint8(8, 0x57); // W
    wav.setUint8(9, 0x41); // A
    wav.setUint8(10, 0x56); // V
    wav.setUint8(11, 0x45); // E

    // fmt chunk
    wav.setUint8(12, 0x66); // f
    wav.setUint8(13, 0x6D); // m
    wav.setUint8(14, 0x74); // t
    wav.setUint8(15, 0x20); // (space)
    wav.setUint32(16, 16, Endian.little); // chunk size
    wav.setUint16(20, 1, Endian.little); // PCM
    wav.setUint16(22, 1, Endian.little); // mono
    wav.setUint32(24, sampleRate, Endian.little);
    wav.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    wav.setUint16(32, 2, Endian.little); // block align
    wav.setUint16(34, 16, Endian.little); // bits per sample

    // data chunk
    wav.setUint8(36, 0x64); // d
    wav.setUint8(37, 0x61); // a
    wav.setUint8(38, 0x74); // t
    wav.setUint8(39, 0x61); // a
    wav.setUint32(40, dataBytes.length, Endian.little);

    final result = Uint8List(wavSize);
    result.setRange(0, 44, wav.buffer.asUint8List());
    result.setRange(44, wavSize, dataBytes);
    return result;
  }
}

final metronomeProvider =
    NotifierProvider<MetronomeNotifier, MetronomeState>(MetronomeNotifier.new);

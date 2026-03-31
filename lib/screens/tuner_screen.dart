import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> with WidgetsBindingObserver {
  final _recorder = AudioRecorder();
  final _pitchDetector = PitchDetector();
  StreamSubscription<Uint8List>? _subscription;

  String _note = '--';
  String _octave = '';
  double _cents = 0;
  double _frequency = 0;
  bool _inTune = false;
  bool _isListening = false;
  String? _error;
  int? _activeString;
  Timer? _silenceTimer;

  final List<double> _pitchHistory = [];
  static const _historySize = 5;

  static const _guitarStrings = [
    (name: 'E2', freq: 82.41, string: 6),
    (name: 'A2', freq: 110.0, string: 5),
    (name: 'D3', freq: 146.83, string: 4),
    (name: 'G3', freq: 196.0, string: 3),
    (name: 'B3', freq: 246.94, string: 2),
    (name: 'E4', freq: 329.63, string: 1),
  ];

  static const _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startListening();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopListening();
    _silenceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopListening();
    } else if (state == AppLifecycleState.resumed) {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) setState(() => _error = 'Microphone permission required');
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
      _subscription = stream.listen(_processAudioData);

      if (mounted) {
        setState(() {
          _isListening = true;
          _error = null;
        });
      }
    } catch (e) {
      dev.log('[Tuner] Failed: $e');
      if (mounted) setState(() => _error = 'Failed: $e');
    }
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _recorder.stop();
    _silenceTimer?.cancel();
  }

  void _processAudioData(Uint8List data) async {
    // Convert PCM16 to float
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

      // Reset silence timer
      _silenceTimer?.cancel();
      _silenceTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _note = '--';
            _octave = '';
            _cents = 0;
            _frequency = 0;
            _inTune = false;
            _activeString = null;
          });
        }
      });

      _pitchHistory.add(rawFreq);
      if (_pitchHistory.length > _historySize) _pitchHistory.removeAt(0);

      final freq = _medianPitch();
      if (freq <= 0) return;

      final midiNote = 12 * log(freq / 440) / ln2 + 69;
      final roundedMidi = midiNote.round();
      final noteIndex = ((roundedMidi % 12) + 12) % 12;
      final octave = (roundedMidi ~/ 12) - 1;
      final cents = (midiNote - roundedMidi) * 100;

      int? closestString;
      double minCentsDist = double.infinity;
      for (int i = 0; i < _guitarStrings.length; i++) {
        final stringMidi = 12 * log(_guitarStrings[i].freq / 440) / ln2 + 69;
        final dist = (midiNote - stringMidi).abs();
        if (dist < 2.0 && dist < minCentsDist) {
          minCentsDist = dist;
          closestString = i;
        }
      }

      if (!mounted) return;
      setState(() {
        _frequency = freq;
        _note = _noteNames[noteIndex];
        _octave = '$octave';
        _cents = cents.clamp(-50, 50);
        _inTune = cents.abs() < 5;
        _activeString = closestString;
      });
    } catch (e) {
      dev.log('[Tuner] Pitch error: $e');
    }
  }

  double _medianPitch() {
    if (_pitchHistory.isEmpty) return 0;
    final sorted = List<double>.from(_pitchHistory)..sort();
    return sorted[sorted.length ~/ 2];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tuner')),
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            Expanded(child: _buildGauge(theme)),
            _buildGuitarStrings(theme),
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: Text(
                _frequency > 0 ? '${_frequency.toStringAsFixed(1)} Hz' : 'Play a note...',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGauge(ThemeData theme) {
    final tuneColor = _inTune ? Colors.green : Colors.orange;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 280,
            height: 40,
            child: CustomPaint(
              painter: _CentsGaugePainter(cents: _cents, inTune: _inTune, isDark: isDark),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening && _note != '--'
                  ? tuneColor.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              border: Border.all(
                color: _isListening && _note != '--'
                    ? tuneColor
                    : Colors.grey.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_note, style: TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold,
                  color: _isListening && _note != '--' ? tuneColor : theme.colorScheme.onSurfaceVariant,
                )),
                if (_octave.isNotEmpty && _note != '--')
                  Text(_octave, style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_isListening && _note != '--')
            Text(
              _inTune ? 'In Tune' : _cents > 0 ? 'Too high' : 'Too low',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tuneColor),
            ),
        ],
      ),
    );
  }

  Widget _buildGuitarStrings(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_guitarStrings.length, (i) {
          final gs = _guitarStrings[i];
          final isActive = _activeString == i;
          final label = gs.name.replaceAll(RegExp(r'\d'), '');
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${gs.string}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? (_inTune ? Colors.green : Colors.orange).withValues(alpha: 0.2) : Colors.transparent,
                  border: Border.all(
                    color: isActive ? (_inTune ? Colors.green : Colors.orange) : Colors.grey.withValues(alpha: 0.3),
                    width: isActive ? 2.5 : 1,
                  ),
                ),
                child: Center(child: Text(label, style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? (_inTune ? Colors.green : Colors.orange) : theme.colorScheme.onSurfaceVariant,
                ))),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _CentsGaugePainter extends CustomPainter {
  final double cents;
  final bool inTune;
  final bool isDark;

  _CentsGaugePainter({required this.cents, required this.inTune, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;
    final midY = size.height / 2;

    canvas.drawLine(Offset(0, midY), Offset(size.width, midY),
      Paint()..color = isDark ? Colors.white12 : Colors.black12..strokeWidth = 4..strokeCap = StrokeCap.round);

    final tickPaint = Paint()..color = isDark ? Colors.white30 : Colors.black26..strokeWidth = 2;
    for (int i = -4; i <= 4; i++) {
      final x = midX + (i / 4) * (size.width / 2 - 10);
      final h = i == 0 ? 14.0 : 6.0;
      canvas.drawLine(Offset(x, midY - h), Offset(x, midY + h), tickPaint);
    }

    final needleX = midX + (cents / 50) * (size.width / 2 - 10);
    final color = inTune ? Colors.green : Colors.orange;
    canvas.drawCircle(Offset(needleX, midY), 8, Paint()..color = color);
    canvas.drawCircle(Offset(needleX, midY), 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _CentsGaugePainter old) => old.cents != cents || old.inTune != inTune;
}

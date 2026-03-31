class AppConfig {
  static const String apiBaseUrl = 'https://api.6strings.app/api';
  static const String appName = 'Sixstrings';

  // Audio
  static const int sampleRate = 44100;
  static const int fftSize = 4096;
  static const int chromaBins = 12;
  static const double chordConfidenceThreshold = 0.6;
  static const int smoothingFrames = 4;

  // UI
  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
}

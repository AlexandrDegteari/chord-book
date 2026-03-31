// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sixstrings';

  @override
  String get searchSongs => 'Search songs...';

  @override
  String get connectionError => 'Connection error';

  @override
  String proxyServerError(String error) {
    return 'Make sure the proxy server is running\n$error';
  }

  @override
  String get noResultsFound => 'No results found';

  @override
  String get searchToGetStarted => 'Search for songs to get started';

  @override
  String get favorites => 'Favorites';

  @override
  String get recent => 'Recent';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get songScreenDefaults => 'Song Screen Defaults';

  @override
  String get autoScroll => 'Auto-scroll';

  @override
  String get autoScrollSubtitle => 'Scroll to current chord automatically';

  @override
  String get detectedChord => 'Detected chord';

  @override
  String get showDetectedChordBadge => 'Show detected chord badge';

  @override
  String get chordDiagram => 'Chord diagram';

  @override
  String get showFingeringDiagram => 'Show fingering diagram';

  @override
  String get about => 'About';

  @override
  String versionInfo(String version) {
    return 'Version $version';
  }

  @override
  String get failedToLoadSong => 'Failed to load song';

  @override
  String get retry => 'Retry';

  @override
  String get transposeDown => 'Transpose down';

  @override
  String get transposeUp => 'Transpose up';

  @override
  String get reset => 'Reset';

  @override
  String get tuner => 'Tuner';

  @override
  String get stop => 'Stop';

  @override
  String get listen => 'Listen';

  @override
  String get smallerText => 'Smaller text';

  @override
  String get largerText => 'Larger text';

  @override
  String get micPermissionRequired => 'Microphone permission required';

  @override
  String get playANote => 'Play a note...';

  @override
  String get inTune => 'In Tune';

  @override
  String get tooHigh => 'Too high';

  @override
  String get tooLow => 'Too low';

  @override
  String get book => 'Book';

  @override
  String get listening => 'Listening...';

  @override
  String get micPermissionDenied => 'Microphone permission denied';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get romanian => 'Romanian';

  @override
  String get metronome => 'Metronome';

  @override
  String get bpm => 'BPM';

  @override
  String get tapTempo => 'Tap Tempo';

  @override
  String get timeSignature => 'Time Signature';

  @override
  String failed(String error) {
    return 'Failed: $error';
  }
}

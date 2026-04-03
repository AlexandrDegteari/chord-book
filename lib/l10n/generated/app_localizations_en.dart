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

  @override
  String get myLibrary => 'My Library';

  @override
  String get playlists => 'Playlists';

  @override
  String get mySongs => 'My Songs';

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get createSong => 'Create Song';

  @override
  String get editSong => 'Edit Song';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get createMyVersion => 'Create My Version';

  @override
  String get playlistTitle => 'Playlist Title';

  @override
  String get playlistDescription => 'Description (optional)';

  @override
  String get songTitle => 'Song Title';

  @override
  String get songArtist => 'Artist';

  @override
  String get addSection => 'Add Section';

  @override
  String get removeSection => 'Remove Section';

  @override
  String get verse => 'Verse';

  @override
  String get chorus => 'Chorus';

  @override
  String get bridge => 'Bridge';

  @override
  String get intro => 'Intro';

  @override
  String get outro => 'Outro';

  @override
  String get solo => 'Solo';

  @override
  String get other => 'Other';

  @override
  String get saveDraft => 'Save Draft';

  @override
  String get submitForReview => 'Submit for Review';

  @override
  String get draft => 'Draft';

  @override
  String get submitted => 'Submitted';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get noPlaylists => 'No playlists yet';

  @override
  String get noMySongs => 'No songs yet';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String get deleteSong => 'Delete Song';

  @override
  String get confirmDelete => 'Are you sure you want to delete this?';

  @override
  String get emptyPlaylist => 'This playlist is empty';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get addToFavorites => 'Favorites';

  @override
  String get newPlaylist => 'New Playlist';

  @override
  String get songContent => 'Lyrics with chords like [Am]text [C]here';

  @override
  String get serverBusy => 'Server is busy';

  @override
  String get serverBusyMessage => 'The server is loading song data. Please try again in a moment.';

  @override
  String get refreshSong => 'Refresh';

  @override
  String nSongs(int count) {
    return '$count songs';
  }
}

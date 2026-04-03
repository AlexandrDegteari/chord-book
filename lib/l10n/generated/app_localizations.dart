import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ro'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sixstrings'**
  String get appTitle;

  /// No description provided for @searchSongs.
  ///
  /// In en, this message translates to:
  /// **'Search songs...'**
  String get searchSongs;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @proxyServerError.
  ///
  /// In en, this message translates to:
  /// **'Make sure the proxy server is running\n{error}'**
  String proxyServerError(String error);

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @searchToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Search for songs to get started'**
  String get searchToGetStarted;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @songScreenDefaults.
  ///
  /// In en, this message translates to:
  /// **'Song Screen Defaults'**
  String get songScreenDefaults;

  /// No description provided for @autoScroll.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll'**
  String get autoScroll;

  /// No description provided for @autoScrollSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scroll to current chord automatically'**
  String get autoScrollSubtitle;

  /// No description provided for @detectedChord.
  ///
  /// In en, this message translates to:
  /// **'Detected chord'**
  String get detectedChord;

  /// No description provided for @showDetectedChordBadge.
  ///
  /// In en, this message translates to:
  /// **'Show detected chord badge'**
  String get showDetectedChordBadge;

  /// No description provided for @chordDiagram.
  ///
  /// In en, this message translates to:
  /// **'Chord diagram'**
  String get chordDiagram;

  /// No description provided for @showFingeringDiagram.
  ///
  /// In en, this message translates to:
  /// **'Show fingering diagram'**
  String get showFingeringDiagram;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionInfo(String version);

  /// No description provided for @failedToLoadSong.
  ///
  /// In en, this message translates to:
  /// **'Failed to load song'**
  String get failedToLoadSong;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @transposeDown.
  ///
  /// In en, this message translates to:
  /// **'Transpose down'**
  String get transposeDown;

  /// No description provided for @transposeUp.
  ///
  /// In en, this message translates to:
  /// **'Transpose up'**
  String get transposeUp;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @tuner.
  ///
  /// In en, this message translates to:
  /// **'Tuner'**
  String get tuner;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @smallerText.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get smallerText;

  /// No description provided for @largerText.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get largerText;

  /// No description provided for @micPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get micPermissionRequired;

  /// No description provided for @playANote.
  ///
  /// In en, this message translates to:
  /// **'Play a note...'**
  String get playANote;

  /// No description provided for @inTune.
  ///
  /// In en, this message translates to:
  /// **'In Tune'**
  String get inTune;

  /// No description provided for @tooHigh.
  ///
  /// In en, this message translates to:
  /// **'Too high'**
  String get tooHigh;

  /// No description provided for @tooLow.
  ///
  /// In en, this message translates to:
  /// **'Too low'**
  String get tooLow;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission denied'**
  String get micPermissionDenied;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @romanian.
  ///
  /// In en, this message translates to:
  /// **'Romanian'**
  String get romanian;

  /// No description provided for @metronome.
  ///
  /// In en, this message translates to:
  /// **'Metronome'**
  String get metronome;

  /// No description provided for @bpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get bpm;

  /// No description provided for @tapTempo.
  ///
  /// In en, this message translates to:
  /// **'Tap Tempo'**
  String get tapTempo;

  /// No description provided for @timeSignature.
  ///
  /// In en, this message translates to:
  /// **'Time Signature'**
  String get timeSignature;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failed(String error);

  /// No description provided for @myLibrary.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get myLibrary;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @mySongs.
  ///
  /// In en, this message translates to:
  /// **'My Songs'**
  String get mySongs;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylist;

  /// No description provided for @createSong.
  ///
  /// In en, this message translates to:
  /// **'Create Song'**
  String get createSong;

  /// No description provided for @editSong.
  ///
  /// In en, this message translates to:
  /// **'Edit Song'**
  String get editSong;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylist;

  /// No description provided for @createMyVersion.
  ///
  /// In en, this message translates to:
  /// **'Create My Version'**
  String get createMyVersion;

  /// No description provided for @playlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlist Title'**
  String get playlistTitle;

  /// No description provided for @playlistDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get playlistDescription;

  /// No description provided for @songTitle.
  ///
  /// In en, this message translates to:
  /// **'Song Title'**
  String get songTitle;

  /// No description provided for @songArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get songArtist;

  /// No description provided for @addSection.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get addSection;

  /// No description provided for @removeSection.
  ///
  /// In en, this message translates to:
  /// **'Remove Section'**
  String get removeSection;

  /// No description provided for @verse.
  ///
  /// In en, this message translates to:
  /// **'Verse'**
  String get verse;

  /// No description provided for @chorus.
  ///
  /// In en, this message translates to:
  /// **'Chorus'**
  String get chorus;

  /// No description provided for @bridge.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get bridge;

  /// No description provided for @intro.
  ///
  /// In en, this message translates to:
  /// **'Intro'**
  String get intro;

  /// No description provided for @outro.
  ///
  /// In en, this message translates to:
  /// **'Outro'**
  String get outro;

  /// No description provided for @solo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get solo;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for Review'**
  String get submitForReview;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @submitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @noPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet'**
  String get noPlaylists;

  /// No description provided for @noMySongs.
  ///
  /// In en, this message translates to:
  /// **'No songs yet'**
  String get noMySongs;

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// No description provided for @deleteSong.
  ///
  /// In en, this message translates to:
  /// **'Delete Song'**
  String get deleteSong;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get confirmDelete;

  /// No description provided for @emptyPlaylist.
  ///
  /// In en, this message translates to:
  /// **'This playlist is empty'**
  String get emptyPlaylist;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get addToFavorites;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newPlaylist;

  /// No description provided for @songContent.
  ///
  /// In en, this message translates to:
  /// **'Lyrics with chords like [Am]text [C]here'**
  String get songContent;

  /// No description provided for @serverBusy.
  ///
  /// In en, this message translates to:
  /// **'Server is busy'**
  String get serverBusy;

  /// No description provided for @serverBusyMessage.
  ///
  /// In en, this message translates to:
  /// **'The server is loading song data. Please try again in a moment.'**
  String get serverBusyMessage;

  /// No description provided for @refreshSong.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshSong;

  /// No description provided for @nSongs.
  ///
  /// In en, this message translates to:
  /// **'{count} songs'**
  String nSongs(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ro', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

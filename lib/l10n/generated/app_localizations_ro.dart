// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Sixstrings';

  @override
  String get searchSongs => 'Cauta melodii...';

  @override
  String get connectionError => 'Eroare de conectare';

  @override
  String proxyServerError(String error) {
    return 'Asigurati-va ca serverul proxy ruleaza\n$error';
  }

  @override
  String get noResultsFound => 'Niciun rezultat gasit';

  @override
  String get searchToGetStarted => 'Cautati o melodie pentru a incepe';

  @override
  String get favorites => 'Favorite';

  @override
  String get recent => 'Recente';

  @override
  String get settings => 'Setari';

  @override
  String get appearance => 'Aspect';

  @override
  String get systemTheme => 'Sistem';

  @override
  String get lightTheme => 'Luminos';

  @override
  String get darkTheme => 'Intunecat';

  @override
  String get songScreenDefaults => 'Setari ecran melodie';

  @override
  String get autoScroll => 'Derulare automata';

  @override
  String get autoScrollSubtitle => 'Deruleaza automat la acordul curent';

  @override
  String get detectedChord => 'Acord detectat';

  @override
  String get showDetectedChordBadge => 'Afiseaza acordul detectat';

  @override
  String get chordDiagram => 'Diagrama acord';

  @override
  String get showFingeringDiagram => 'Afiseaza diagrama de digitatie';

  @override
  String get about => 'Despre';

  @override
  String versionInfo(String version) {
    return 'Versiunea $version';
  }

  @override
  String get failedToLoadSong => 'Nu s-a putut incarca melodia';

  @override
  String get retry => 'Reincercare';

  @override
  String get transposeDown => 'Transpune in jos';

  @override
  String get transposeUp => 'Transpune in sus';

  @override
  String get reset => 'Resetare';

  @override
  String get tuner => 'Acordor';

  @override
  String get stop => 'Stop';

  @override
  String get listen => 'Asculta';

  @override
  String get smallerText => 'Text mai mic';

  @override
  String get largerText => 'Text mai mare';

  @override
  String get micPermissionRequired => 'Este necesara permisiunea microfonului';

  @override
  String get playANote => 'Cantati o nota...';

  @override
  String get inTune => 'Acordat';

  @override
  String get tooHigh => 'Prea sus';

  @override
  String get tooLow => 'Prea jos';

  @override
  String get book => 'Melodii';

  @override
  String get listening => 'Ascult...';

  @override
  String get micPermissionDenied => 'Permisiune microfon refuzata';

  @override
  String get language => 'Limba';

  @override
  String get systemLanguage => 'Sistem';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get romanian => 'Romana';

  @override
  String get metronome => 'Metronom';

  @override
  String get bpm => 'BPM';

  @override
  String get tapTempo => 'Tempo prin atingere';

  @override
  String get timeSignature => 'Metrica';

  @override
  String failed(String error) {
    return 'Eroare: $error';
  }
}

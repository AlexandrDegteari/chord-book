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

  @override
  String get myLibrary => 'Biblioteca mea';

  @override
  String get playlists => 'Playlisturi';

  @override
  String get mySongs => 'Melodiile mele';

  @override
  String get createPlaylist => 'Creeaza playlist';

  @override
  String get createSong => 'Creeaza melodie';

  @override
  String get editSong => 'Editeaza melodia';

  @override
  String get addToPlaylist => 'Adauga in playlist';

  @override
  String get createMyVersion => 'Creeaza versiunea mea';

  @override
  String get playlistTitle => 'Titlu playlist';

  @override
  String get playlistDescription => 'Descriere (optional)';

  @override
  String get songTitle => 'Titlu melodie';

  @override
  String get songArtist => 'Artist';

  @override
  String get addSection => 'Adauga sectiune';

  @override
  String get removeSection => 'Sterge sectiune';

  @override
  String get verse => 'Strofa';

  @override
  String get chorus => 'Refren';

  @override
  String get bridge => 'Punte';

  @override
  String get intro => 'Intro';

  @override
  String get outro => 'Outro';

  @override
  String get solo => 'Solo';

  @override
  String get other => 'Altele';

  @override
  String get saveDraft => 'Salveaza ciorna';

  @override
  String get submitForReview => 'Trimite pentru verificare';

  @override
  String get draft => 'Ciorna';

  @override
  String get submitted => 'Trimis';

  @override
  String get approved => 'Aprobat';

  @override
  String get rejected => 'Respins';

  @override
  String get noPlaylists => 'Niciun playlist inca';

  @override
  String get noMySongs => 'Nicio melodie inca';

  @override
  String get deletePlaylist => 'Sterge playlist';

  @override
  String get deleteSong => 'Sterge melodia';

  @override
  String get confirmDelete => 'Sunteti sigur ca doriti sa stergeti?';

  @override
  String get emptyPlaylist => 'Acest playlist este gol';

  @override
  String get cancel => 'Anuleaza';

  @override
  String get delete => 'Sterge';

  @override
  String get create => 'Creeaza';

  @override
  String get save => 'Salveaza';

  @override
  String get addToFavorites => 'Favorite';

  @override
  String get newPlaylist => 'Playlist nou';

  @override
  String get songContent => 'Versuri cu acorduri: [Am]text [C]aici';

  @override
  String get serverBusy => 'Server ocupat';

  @override
  String get serverBusyMessage => 'Serverul incarca datele melodiei. Incercati din nou in cateva secunde.';

  @override
  String get refreshSong => 'Reîmprospătare';

  @override
  String nSongs(int count) {
    return '$count melodii';
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongSettings {
  final bool autoScrollEnabled;
  final bool showDetectedChord;
  final bool showChordDiagram;

  const SongSettings({
    this.autoScrollEnabled = true,
    this.showDetectedChord = true,
    this.showChordDiagram = false,
  });

  SongSettings copyWith({
    bool? autoScrollEnabled,
    bool? showDetectedChord,
    bool? showChordDiagram,
  }) {
    return SongSettings(
      autoScrollEnabled: autoScrollEnabled ?? this.autoScrollEnabled,
      showDetectedChord: showDetectedChord ?? this.showDetectedChord,
      showChordDiagram: showChordDiagram ?? this.showChordDiagram,
    );
  }
}

final songSettingsProvider =
    NotifierProvider<SongSettingsNotifier, SongSettings>(SongSettingsNotifier.new);

class SongSettingsNotifier extends Notifier<SongSettings> {
  static const _keyAutoScroll = 'song_auto_scroll';
  static const _keyDetectedChord = 'song_detected_chord';
  static const _keyChordDiagram = 'song_chord_diagram';

  @override
  SongSettings build() {
    Future.microtask(() => _load());
    return const SongSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SongSettings(
      autoScrollEnabled: prefs.getBool(_keyAutoScroll) ?? true,
      showDetectedChord: prefs.getBool(_keyDetectedChord) ?? true,
      showChordDiagram: prefs.getBool(_keyChordDiagram) ?? false,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoScroll, state.autoScrollEnabled);
    await prefs.setBool(_keyDetectedChord, state.showDetectedChord);
    await prefs.setBool(_keyChordDiagram, state.showChordDiagram);
  }

  void toggleAutoScroll() {
    state = state.copyWith(autoScrollEnabled: !state.autoScrollEnabled);
    _save();
  }

  void toggleDetectedChord() {
    state = state.copyWith(showDetectedChord: !state.showDetectedChord);
    _save();
  }

  void toggleChordDiagram() {
    state = state.copyWith(showChordDiagram: !state.showChordDiagram);
    _save();
  }
}

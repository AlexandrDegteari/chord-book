import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/user_song.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';

final userSongsProvider =
    NotifierProvider<UserSongsNotifier, List<UserSong>>(UserSongsNotifier.new);

class UserSongsNotifier extends Notifier<List<UserSong>> {
  final _db = DatabaseHelper();
  final _api = ApiService();

  @override
  List<UserSong> build() {
    Future.microtask(() => _load());
    return [];
  }

  Future<void> _load() async {
    final rows = await _db.getUserSongs();
    state = rows.map((r) => UserSong.fromDb(r)).toList();
  }

  Future<UserSong> create({
    required String title,
    required String artist,
    required List<SongSection> sections,
    String? originalSongId,
  }) async {
    final id = const Uuid().v4();
    final sectionsJson = sections.map((s) => s.toJson()).toList();
    final row = await _db.createUserSong(id, title, artist, sectionsJson,
        originalSongId: originalSongId);
    final song = UserSong.fromDb(row);
    state = [song, ...state];

    // Sync to backend
    try {
      await _api.createUserSong(
        title: title,
        artist: artist,
        sections: sectionsJson,
        originalSongId: originalSongId,
      );
    } catch (_) {}

    return song;
  }

  Future<void> update(String id, {
    String? title,
    String? artist,
    List<SongSection>? sections,
  }) async {
    final sectionsJson = sections?.map((s) => s.toJson()).toList();
    await _db.updateUserSong(id,
        title: title, artist: artist, sections: sectionsJson);
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(title: title, artist: artist, sections: sections);
      }
      return s;
    }).toList();

    try {
      await _api.updateUserSong(id,
          title: title, artist: artist, sections: sectionsJson);
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    await _db.deleteUserSong(id);
    state = state.where((s) => s.id != id).toList();
    try {
      await _api.deleteUserSong(id);
    } catch (_) {}
  }

  Future<void> submit(String id) async {
    await _db.updateUserSong(id, status: 'submitted');
    state = state.map((s) {
      if (s.id == id) return s.copyWith(status: 'submitted');
      return s;
    }).toList();
    try {
      await _api.submitUserSong(id);
    } catch (_) {}
  }

  Future<void> refresh() async {
    await _load();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist.dart';
import '../models/search_result.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';

final playlistsProvider =
    NotifierProvider<PlaylistsNotifier, List<Playlist>>(PlaylistsNotifier.new);

class PlaylistsNotifier extends Notifier<List<Playlist>> {
  final _db = DatabaseHelper();
  final _api = ApiService();

  @override
  List<Playlist> build() {
    Future.microtask(() => _load());
    return [];
  }

  Future<void> _load() async {
    final rows = await _db.getPlaylists();
    state = rows.map((r) => Playlist.fromDb(r)).toList();
    _syncFromRemote();
  }

  Future<void> _syncFromRemote() async {
    try {
      await _api.getPlaylists();
      // TODO: merge remote playlists with local
    } catch (_) {
      // Offline — local data is fine
    }
  }

  Future<Playlist> create(String title, {String? description}) async {
    final id = const Uuid().v4();
    final row = await _db.createPlaylist(id, title, description: description);
    final playlist = Playlist.fromDb(row);
    state = [playlist, ...state];

    // Sync to backend
    try {
      await _api.createPlaylist(title, description: description);
    } catch (_) {}

    return playlist;
  }

  Future<void> update(String id, {String? title, String? description}) async {
    await _db.updatePlaylist(id, title: title, description: description);
    state = state.map((p) {
      if (p.id == id) return p.copyWith(title: title, description: description);
      return p;
    }).toList();
  }

  Future<void> delete(String id) async {
    await _db.deletePlaylist(id);
    state = state.where((p) => p.id != id).toList();
    try {
      await _api.deletePlaylist(id);
    } catch (_) {}
  }

  Future<void> refresh() async {
    await _load();
  }
}

// Provider for songs within a specific playlist
final playlistSongsProvider =
    FutureProvider.family<List<SearchResult>, String>((ref, playlistId) async {
  final db = DatabaseHelper();
  return db.getPlaylistSongs(playlistId);
});

// Provider to check which playlists contain a song
final songPlaylistsProvider =
    FutureProvider.family<List<String>, String>((ref, songId) async {
  final db = DatabaseHelper();
  return db.getPlaylistIdsForSong(songId);
});

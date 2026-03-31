import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_result.dart';
import '../services/database_helper.dart';
import '../services/keychain_backup.dart';

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<SearchResult>>(
        FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<List<SearchResult>> {
  static const _legacyKey = 'favorites';
  final _db = DatabaseHelper();

  @override
  List<SearchResult> build() {
    Future.microtask(() => _load());
    return [];
  }

  Future<void> _load() async {
    // Migrate legacy SharedPreferences data
    await _migrateLegacy();

    // Load from SQLite
    var favorites = await _db.getFavorites();

    // If empty, try restoring from Keychain (post-reinstall)
    if (favorites.isEmpty) {
      final restored = await KeychainBackup.restoreFavorites();
      if (restored != null && restored.isNotEmpty) {
        await _db.insertFavorites(restored);
        favorites = await _db.getFavorites();
      }
    }

    state = favorites;
  }

  Future<void> _migrateLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_legacyKey);
    if (data != null && data.isNotEmpty) {
      final songs = data
          .map((s) => SearchResult.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      await _db.insertFavorites(songs);
      await KeychainBackup.backupFavorites(songs);
      await prefs.remove(_legacyKey);
    }
  }

  bool isFavorite(String songId) {
    return state.any((s) => s.id == songId);
  }

  Future<void> toggle(SearchResult song) async {
    if (isFavorite(song.id)) {
      await _db.removeFavorite(song.id);
      state = state.where((s) => s.id != song.id).toList();
    } else {
      await _db.addFavorite(song);
      state = [...state, song];
    }
    await KeychainBackup.backupFavorites(state);
  }
}

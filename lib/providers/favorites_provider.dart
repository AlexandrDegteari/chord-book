import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_result.dart';

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<SearchResult>>(
        FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<List<SearchResult>> {
  static const _key = 'favorites';

  @override
  List<SearchResult> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key);
    if (data != null) {
      state = data
          .map((s) => SearchResult.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      state.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  bool isFavorite(String songId) {
    return state.any((s) => s.id == songId);
  }

  Future<void> toggle(SearchResult song) async {
    if (isFavorite(song.id)) {
      state = state.where((s) => s.id != song.id).toList();
    } else {
      state = [...state, song];
    }
    await _save();
  }
}

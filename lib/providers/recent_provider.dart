import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_result.dart';

final recentProvider =
    NotifierProvider<RecentNotifier, List<SearchResult>>(RecentNotifier.new);

class RecentNotifier extends Notifier<List<SearchResult>> {
  static const _key = 'recent_songs';
  static const _maxRecent = 20;

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
          .map((s) =>
              SearchResult.fromJson(jsonDecode(s) as Map<String, dynamic>))
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

  Future<void> addRecent(SearchResult song) async {
    // Remove if already exists, then add to front
    final filtered = state.where((s) => s.id != song.id).toList();
    state = [song, ...filtered].take(_maxRecent).toList();
    await _save();
  }
}

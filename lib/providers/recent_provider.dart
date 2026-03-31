import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_result.dart';
import '../services/database_helper.dart';

final recentProvider =
    NotifierProvider<RecentNotifier, List<SearchResult>>(RecentNotifier.new);

class RecentNotifier extends Notifier<List<SearchResult>> {
  static const _legacyKey = 'recent_songs';
  static const _maxRecent = 20;
  final _db = DatabaseHelper();

  @override
  List<SearchResult> build() {
    Future.microtask(() => _load());
    return [];
  }

  Future<void> _load() async {
    await _migrateLegacy();
    state = await _db.getRecent(limit: _maxRecent);
  }

  Future<void> _migrateLegacy() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_legacyKey);
    if (data != null && data.isNotEmpty) {
      final songs = data
          .map((s) =>
              SearchResult.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      await _db.insertRecent(songs);
      await prefs.remove(_legacyKey);
    }
  }

  Future<void> addRecent(SearchResult song) async {
    await _db.addRecent(song, maxRecent: _maxRecent);
    state = await _db.getRecent(limit: _maxRecent);
  }
}

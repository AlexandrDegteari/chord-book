import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/search_result.dart';

class KeychainBackup {
  static const _favoritesKey = 'favorites_backup';
  static const _storage = FlutterSecureStorage();

  static Future<void> backupFavorites(List<SearchResult> favorites) async {
    final json = jsonEncode(favorites.map((s) => s.toJson()).toList());
    await _storage.write(key: _favoritesKey, value: json);
  }

  static Future<List<SearchResult>?> restoreFavorites() async {
    final json = await _storage.read(key: _favoritesKey);
    if (json == null) return null;
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}

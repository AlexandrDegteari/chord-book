import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/search_result.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'sixstrings.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            url TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE recent_songs(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            url TEXT NOT NULL,
            viewed_at INTEGER NOT NULL
          )
        ''');
        await _createV2Tables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createV2Tables(db);
        }
      },
    );
  }

  static Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlists(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        remote_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_songs(
        playlist_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        url TEXT NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, song_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_songs(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        sections TEXT NOT NULL,
        original_song_id TEXT,
        status TEXT NOT NULL DEFAULT 'draft',
        remote_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  // Favorites

  Future<List<SearchResult>> getFavorites() async {
    final db = await database;
    final rows = await db.query('favorites', orderBy: 'created_at ASC');
    return rows.map((r) => SearchResult(
      id: r['id'] as String,
      title: r['title'] as String,
      artist: r['artist'] as String,
      url: r['url'] as String,
    )).toList();
  }

  Future<void> addFavorite(SearchResult song) async {
    final db = await database;
    await db.insert('favorites', {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'url': song.url,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFavorite(String id) async {
    final db = await database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertFavorites(List<SearchResult> songs) async {
    final db = await database;
    final batch = db.batch();
    for (final song in songs) {
      batch.insert('favorites', {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'url': song.url,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // Recent songs

  Future<List<SearchResult>> getRecent({int limit = 20}) async {
    final db = await database;
    final rows = await db.query('recent_songs',
        orderBy: 'viewed_at DESC', limit: limit);
    return rows.map((r) => SearchResult(
      id: r['id'] as String,
      title: r['title'] as String,
      artist: r['artist'] as String,
      url: r['url'] as String,
    )).toList();
  }

  Future<void> removeRecent(String id) async {
    final db = await database;
    await db.delete('recent_songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addRecent(SearchResult song, {int maxRecent = 20}) async {
    final db = await database;
    await db.insert('recent_songs', {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'url': song.url,
      'viewed_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Trim to max
    await db.rawDelete('''
      DELETE FROM recent_songs WHERE id NOT IN (
        SELECT id FROM recent_songs ORDER BY viewed_at DESC LIMIT ?
      )
    ''', [maxRecent]);
  }

  Future<void> insertRecent(List<SearchResult> songs) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < songs.length; i++) {
      batch.insert('recent_songs', {
        'id': songs[i].id,
        'title': songs[i].title,
        'artist': songs[i].artist,
        'url': songs[i].url,
        'viewed_at': now - (songs.length - i),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // Playlists

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final db = await database;
    final rows = await db.query('playlists', orderBy: 'created_at DESC');
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final songCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM playlist_songs WHERE playlist_id = ?',
        [row['id']],
      ));
      result.add({...row, 'song_count': songCount ?? 0});
    }
    return result;
  }

  Future<Map<String, dynamic>> createPlaylist(String id, String title, {String? description}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = {
      'id': id,
      'title': title,
      'description': description,
      'created_at': now,
      'updated_at': now,
    };
    await db.insert('playlists', row);
    return {...row, 'song_count': 0};
  }

  Future<void> updatePlaylist(String id, {String? title, String? description}) async {
    final db = await database;
    final values = <String, dynamic>{'updated_at': DateTime.now().millisecondsSinceEpoch};
    if (title != null) values['title'] = title;
    if (description != null) values['description'] = description;
    await db.update('playlists', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePlaylist(String id) async {
    final db = await database;
    await db.delete('playlist_songs', where: 'playlist_id = ?', whereArgs: [id]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SearchResult>> getPlaylistSongs(String playlistId) async {
    final db = await database;
    final rows = await db.query('playlist_songs',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
        orderBy: 'position ASC, added_at ASC');
    return rows.map((r) => SearchResult(
      id: r['song_id'] as String,
      title: r['title'] as String,
      artist: r['artist'] as String,
      url: r['url'] as String,
    )).toList();
  }

  Future<void> addSongToPlaylist(String playlistId, SearchResult song) async {
    final db = await database;
    final maxPos = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT MAX(position) FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    ));
    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': song.id,
      'title': song.title,
      'artist': song.artist,
      'url': song.url,
      'position': (maxPos ?? -1) + 1,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final db = await database;
    await db.delete('playlist_songs',
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, songId]);
  }

  Future<List<String>> getPlaylistIdsForSong(String songId) async {
    final db = await database;
    final rows = await db.query('playlist_songs',
        columns: ['playlist_id'],
        where: 'song_id = ?',
        whereArgs: [songId]);
    return rows.map((r) => r['playlist_id'] as String).toList();
  }

  // User Songs

  Future<List<Map<String, dynamic>>> getUserSongs() async {
    final db = await database;
    return db.query('user_songs', orderBy: 'updated_at DESC');
  }

  Future<Map<String, dynamic>> createUserSong(String id, String title, String artist,
      List<Map<String, dynamic>> sections, {String? originalSongId}) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = {
      'id': id,
      'title': title,
      'artist': artist,
      'sections': jsonEncode(sections),
      'original_song_id': originalSongId,
      'status': 'draft',
      'created_at': now,
      'updated_at': now,
    };
    await db.insert('user_songs', row);
    return row;
  }

  Future<void> updateUserSong(String id, {String? title, String? artist,
      List<Map<String, dynamic>>? sections, String? status}) async {
    final db = await database;
    final values = <String, dynamic>{'updated_at': DateTime.now().millisecondsSinceEpoch};
    if (title != null) values['title'] = title;
    if (artist != null) values['artist'] = artist;
    if (sections != null) values['sections'] = jsonEncode(sections);
    if (status != null) values['status'] = status;
    await db.update('user_songs', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteUserSong(String id) async {
    final db = await database;
    await db.delete('user_songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getUserSong(String id) async {
    final db = await database;
    final rows = await db.query('user_songs', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }
}

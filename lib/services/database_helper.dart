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
      version: 1,
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
      },
    );
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
}

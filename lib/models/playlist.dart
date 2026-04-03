import 'search_result.dart';

class Playlist {
  final String id;
  final String title;
  final String? description;
  final String? remoteId;
  final int songCount;
  final List<SearchResult> songs;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Playlist({
    required this.id,
    required this.title,
    this.description,
    this.remoteId,
    this.songCount = 0,
    this.songs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.fromDb(Map<String, dynamic> row) {
    return Playlist(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      remoteId: row['remote_id'] as String?,
      songCount: (row['song_count'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  Playlist copyWith({
    String? title,
    String? description,
    int? songCount,
    List<SearchResult>? songs,
  }) {
    return Playlist(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      remoteId: remoteId,
      songCount: songCount ?? this.songCount,
      songs: songs ?? this.songs,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

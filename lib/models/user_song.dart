import 'dart:convert';

class SongSection {
  final String type;
  final String content;

  const SongSection({required this.type, required this.content});

  Map<String, dynamic> toJson() => {'type': type, 'content': content};

  factory SongSection.fromJson(Map<String, dynamic> json) {
    return SongSection(
      type: json['type'] as String,
      content: json['content'] as String,
    );
  }
}

class UserSong {
  final String id;
  final String title;
  final String artist;
  final List<SongSection> sections;
  final String? originalSongId;
  final String status;
  final String? remoteId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.sections,
    this.originalSongId,
    this.status = 'draft',
    this.remoteId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSong.fromDb(Map<String, dynamic> row) {
    final sectionsJson = jsonDecode(row['sections'] as String) as List;
    return UserSong(
      id: row['id'] as String,
      title: row['title'] as String,
      artist: row['artist'] as String,
      sections: sectionsJson
          .map((s) => SongSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      originalSongId: row['original_song_id'] as String?,
      status: row['status'] as String,
      remoteId: row['remote_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  UserSong copyWith({
    String? title,
    String? artist,
    List<SongSection>? sections,
    String? status,
  }) {
    return UserSong(
      id: id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      sections: sections ?? this.sections,
      originalSongId: originalSongId,
      status: status ?? this.status,
      remoteId: remoteId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  List<Map<String, dynamic>> sectionsToJson() =>
      sections.map((s) => s.toJson()).toList();
}

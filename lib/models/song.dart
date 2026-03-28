import 'song_section.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String url;
  final List<SongSection> sections;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.url = '',
    this.sections = const [],
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      url: json['url'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) => SongSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'url': url,
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}

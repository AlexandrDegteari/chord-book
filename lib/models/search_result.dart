class SearchResult {
  final String id;
  final String title;
  final String artist;
  final String url;

  const SearchResult({
    required this.id,
    required this.title,
    required this.artist,
    required this.url,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'url': url,
      };
}

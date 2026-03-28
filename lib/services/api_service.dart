import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/search_result.dart';
import '../models/song.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  Future<List<SearchResult>> search(String query) async {
    final response = await _dio.get('/search', queryParameters: {'q': query});
    final data = response.data as List<dynamic>;
    return data
        .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Song> getSong(String songId) async {
    final response = await _dio.get('/song/$songId');
    return Song.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Song> getSongByUrl(String url) async {
    final response =
        await _dio.get('/song-by-url', queryParameters: {'url': url});
    return Song.fromJson(response.data as Map<String, dynamic>);
  }
}

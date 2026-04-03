import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/search_result.dart';
import '../models/song.dart';
import 'device_service.dart';

class ServerBusyException implements Exception {
  @override
  String toString() => 'Server is busy';
}

class ApiService {
  late final Dio _dio;
  bool _deviceRegistered = false;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final uuid = await DeviceService.getDeviceUuid();
        options.headers['X-Device-UUID'] = uuid;
        handler.next(options);
      },
    ));
  }

  Future<void> _ensureRegistered() async {
    if (_deviceRegistered) return;
    try {
      final uuid = await DeviceService.getDeviceUuid();
      await _dio.post('/devices/register', data: {'deviceUuid': uuid});
      _deviceRegistered = true;
    } catch (_) {
      // Registration may fail offline — that's ok for local-first features
    }
  }

  Future<List<SearchResult>> search(String query) async {
    final response = await _dio.get('/search', queryParameters: {'q': query});
    final data = response.data as List<dynamic>;
    return data
        .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Song> getSong(String songId) async {
    try {
      final response = await _dio.get('/song/$songId');
      return Song.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw ServerBusyException();
      }
      rethrow;
    }
  }

  Future<Song> getSongByUrl(String url) async {
    try {
      final response =
          await _dio.get('/song-by-url', queryParameters: {'url': url});
      return Song.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw ServerBusyException();
      }
      rethrow;
    }
  }

  // Playlists

  Future<List<dynamic>> getPlaylists() async {
    await _ensureRegistered();
    final response = await _dio.get('/playlists');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createPlaylist(String title, {String? description}) async {
    await _ensureRegistered();
    final response = await _dio.post('/playlists', data: {
      'title': title,
      'description': ?description,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPlaylist(String id) async {
    final response = await _dio.get('/playlists/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<void> updatePlaylist(String id, {String? title, String? description}) async {
    await _dio.patch('/playlists/$id', data: {
      'title': ?title,
      'description': ?description,
    });
  }

  Future<void> deletePlaylist(String id) async {
    await _dio.delete('/playlists/$id');
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await _dio.post('/playlists/$playlistId/songs', data: {'songId': songId});
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _dio.delete('/playlists/$playlistId/songs/$songId');
  }

  // User Songs

  Future<List<dynamic>> getUserSongs() async {
    await _ensureRegistered();
    final response = await _dio.get('/user-songs');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createUserSong({
    required String title,
    required String artist,
    required List<dynamic> sections,
    String? originalSongId,
  }) async {
    await _ensureRegistered();
    final response = await _dio.post('/user-songs', data: {
      'title': title,
      'artist': artist,
      'sections': sections,
      'originalSongId': ?originalSongId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUserSong(String id) async {
    final response = await _dio.get('/user-songs/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateUserSong(String id, {
    String? title,
    String? artist,
    List<dynamic>? sections,
  }) async {
    await _dio.put('/user-songs/$id', data: {
      'title': ?title,
      'artist': ?artist,
      'sections': ?sections,
    });
  }

  Future<void> deleteUserSong(String id) async {
    await _dio.delete('/user-songs/$id');
  }

  Future<void> submitUserSong(String id) async {
    await _dio.post('/user-songs/$id/submit');
  }
}

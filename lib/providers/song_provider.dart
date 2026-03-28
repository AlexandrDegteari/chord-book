import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../services/chord_service.dart';
import 'search_provider.dart';

final currentSongProvider =
    FutureProvider.family<Song, String>((ref, songUrl) async {
  return ref.read(apiServiceProvider).getSongByUrl(songUrl);
});

final transposeProvider =
    NotifierProvider<TransposeNotifier, int>(TransposeNotifier.new);

class TransposeNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

final transposedSongProvider =
    Provider.family<AsyncValue<Song>, String>((ref, songUrl) {
  final songAsync = ref.watch(currentSongProvider(songUrl));
  final semitones = ref.watch(transposeProvider);

  return songAsync.whenData((song) {
    if (semitones == 0) return song;
    return ChordService.transposeSong(song, semitones);
  });
});

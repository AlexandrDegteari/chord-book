import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/search_result.dart';
import '../services/api_service.dart';

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
  void clear() => state = '';
}

final searchResultsProvider =
    FutureProvider.autoDispose<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().length < 2) return [];

  await Future.delayed(const Duration(milliseconds: 500));
  if (ref.read(searchQueryProvider) != query) return [];

  return ref.read(apiServiceProvider).search(query);
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

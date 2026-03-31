import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../config/design_tokens.dart';
import '../models/search_result.dart';
import '../providers/favorites_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/recent_provider.dart';
import '../providers/search_provider.dart';
import '../providers/speech_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/song_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToSong(SearchResult result) {
    ref.read(recentProvider.notifier).addRecent(result);
    context.push(
      '/song?url=${Uri.encodeComponent(result.url)}'
      '&title=${Uri.encodeComponent(result.title)}'
      '&artist=${Uri.encodeComponent(result.artist)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final favorites = ref.watch(favoritesProvider);
    final recent = ref.watch(recentProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final speechState = ref.watch(speechProvider);

    ref.listen(speechProvider, (prev, next) {
      if (next.recognizedText.isNotEmpty &&
          next.recognizedText != (prev?.recognizedText ?? '')) {
        _searchController.text = next.recognizedText;
        ref.read(searchQueryProvider.notifier).set(next.recognizedText);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: _themeIcon(ref.watch(themeProvider)),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchSongs,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        speechState.isListening ? Icons.mic : Icons.mic_none,
                        color: speechState.isListening
                            ? theme.colorScheme.error
                            : null,
                      ),
                      onPressed: () {
                        final locale = ref.read(localeProvider);
                        final localeId = locale != null
                            ? '${locale.languageCode}_${locale.languageCode.toUpperCase()}'
                            : null;
                        ref
                            .read(speechProvider.notifier)
                            .toggle(localeId: localeId);
                      },
                    ),
                    if (query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).clear();
                        },
                      ),
                  ],
                ),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).set(value);
              },
            ),
          ),
          Expanded(
            child: query.isNotEmpty
                ? _buildSearchResults(searchResults, l10n)
                : _buildHomeContent(favorites, recent, theme, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
      AsyncValue<List<SearchResult>> results, AppLocalizations l10n) {
    return switch (results) {
      AsyncValue(:final error?) => Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: DesignTokens.spacingSm),
                Text(l10n.connectionError,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: DesignTokens.spacingXs),
                Text(
                  l10n.proxyServerError(error.toString()),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      AsyncValue(:final value?) => value.isEmpty
          ? Center(child: Text(l10n.noResultsFound))
          : ListView.builder(
              itemCount: value.length,
              itemBuilder: (context, index) {
                final result = value[index];
                final favs = ref.watch(favoritesProvider);
                final isFav = favs.any((f) => f.id == result.id);
                return SongCard(
                  result: result,
                  isFavorite: isFav,
                  onFavoriteToggle: () =>
                      ref.read(favoritesProvider.notifier).toggle(result),
                  onTap: () => _navigateToSong(result),
                );
              },
            ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildHomeContent(List<SearchResult> favorites,
      List<SearchResult> recent, ThemeData theme, AppLocalizations l10n) {
    if (favorites.isEmpty && recent.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note,
                size: 64, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(l10n.searchToGetStarted,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (favorites.isNotEmpty) ...[
          _sectionTitle(l10n.favorites, theme),
          ...favorites.map((result) => SongCard(
                result: result,
                isFavorite: true,
                onFavoriteToggle: () =>
                    ref.read(favoritesProvider.notifier).toggle(result),
                onTap: () => _navigateToSong(result),
              )),
          const SizedBox(height: DesignTokens.spacingSm),
        ],
        if (recent.isNotEmpty) ...[
          _sectionTitle(l10n.recent, theme),
          ...recent.map((result) {
            final isFav =
                ref.watch(favoritesProvider).any((f) => f.id == result.id);
            return SongCard(
              result: result,
              isFavorite: isFav,
              onFavoriteToggle: () =>
                  ref.read(favoritesProvider.notifier).toggle(result),
              onTap: () => _navigateToSong(result),
            );
          }),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.spacingMd, DesignTokens.spacingSm,
          DesignTokens.spacingMd, 0),
      child: Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface)),
    );
  }

  Icon _themeIcon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => const Icon(Icons.light_mode),
      ThemeMode.dark => const Icon(Icons.dark_mode),
      ThemeMode.system => const Icon(Icons.brightness_auto),
    };
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/design_tokens.dart';
import '../models/search_result.dart';
import '../providers/favorites_provider.dart';
import '../providers/song_provider.dart';
import '../utils/chord_utils.dart';
import '../widgets/chord_line.dart';
import '../widgets/section_header.dart';

class SongScreen extends ConsumerStatefulWidget {
  final String songUrl;
  final String title;
  final String artist;

  const SongScreen({
    super.key,
    required this.songUrl,
    this.title = '',
    this.artist = '',
  });

  @override
  ConsumerState<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends ConsumerState<SongScreen> {
  double _fontSize = 16.0;

  @override
  void deactivate() {
    // Reset transpose when leaving screen
    ref.read(transposeProvider.notifier).reset();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final songAsync = ref.watch(transposedSongProvider(widget.songUrl));
    final transpose = ref.watch(transposeProvider);
    final theme = Theme.of(context);

    final displayTitle = songAsync.value?.title ?? widget.title;
    final displayArtist = songAsync.value?.artist ?? widget.artist;
    final songId = songAsync.value?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(displayTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (displayArtist.isNotEmpty)
              Text(displayArtist,
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          if (songId.isNotEmpty)
            Builder(builder: (context) {
              final favs = ref.watch(favoritesProvider);
              final isFav = favs.any((f) => f.id == songId);
              return IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : null),
                onPressed: () {
                  final song = songAsync.value!;
                  ref.read(favoritesProvider.notifier).toggle(SearchResult(
                    id: song.id,
                    title: song.title,
                    artist: song.artist,
                    url: widget.songUrl,
                  ));
                },
              );
            }),
        ],
      ),
      body: switch (songAsync) {
        AsyncValue(:final error?) => Center(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48,
                      color: theme.colorScheme.error),
                  const SizedBox(height: DesignTokens.spacingSm),
                  Text('Failed to load song',
                      style: TextStyle(
                          fontSize: 16, color: theme.colorScheme.error)),
                  const SizedBox(height: DesignTokens.spacingXs),
                  Text('$error',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: DesignTokens.spacingMd),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(currentSongProvider(widget.songUrl)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        AsyncValue(:final value?) => Column(
            children: [
              // Toolbar
              _buildToolbar(theme, transpose),
              // Song content
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.spacingMd),
                  itemCount: value.sections.length,
                  itemBuilder: (context, sectionIndex) {
                    final section = value.sections[sectionIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (section.label.isNotEmpty)
                          SectionHeader(section: section),
                        ...section.lines.map(
                          (line) => ChordLineWidget(
                              line: line, fontSize: _fontSize),
                        ),
                        if (sectionIndex < value.sections.length - 1)
                          const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildToolbar(ThemeData theme, int transpose) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSm,
        vertical: DesignTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
              color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Transpose controls
          IconButton(
            onPressed: () => ref.read(transposeProvider.notifier).decrement(),
            icon: const Icon(Icons.remove, size: 18),
            tooltip: 'Transpose down',
            visualDensity: VisualDensity.compact,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            alignment: Alignment.center,
            child: Text(
              ChordUtils.formatTranspose(transpose),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'monospace',
                color: transpose != 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(transposeProvider.notifier).increment(),
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Transpose up',
            visualDensity: VisualDensity.compact,
          ),
          if (transpose != 0)
            TextButton(
              onPressed: () => ref.read(transposeProvider.notifier).reset(),
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: const Text('Reset', style: TextStyle(fontSize: 12)),
            ),

          const Spacer(),

          // Font size controls
          IconButton(
            onPressed: _fontSize > 12
                ? () => setState(() => _fontSize -= 2)
                : null,
            icon: const Icon(Icons.text_decrease, size: 18),
            tooltip: 'Smaller text',
            visualDensity: VisualDensity.compact,
          ),
          Text('${_fontSize.toInt()}',
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          IconButton(
            onPressed: _fontSize < 24
                ? () => setState(() => _fontSize += 2)
                : null,
            icon: const Icon(Icons.text_increase, size: 18),
            tooltip: 'Larger text',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

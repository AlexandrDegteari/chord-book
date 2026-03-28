import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/design_tokens.dart';
import '../models/search_result.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/song_provider.dart';
import '../utils/chord_utils.dart';
import '../widgets/chord_detector_overlay.dart';
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
  final ScrollController _scrollController = ScrollController();

  // Keys for each line to enable scroll-to
  final Map<String, GlobalKey> _lineKeys = {};
  String _lastScrolledChord = '';

  @override
  void deactivate() {
    ref.read(transposeProvider.notifier).reset();
    ref.read(audioProvider.notifier).stopListening();
    super.deactivate();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Build a unique key for a line at [sectionIndex]:[lineIndex]
  String _lineKeyId(int sectionIndex, int lineIndex) =>
      '$sectionIndex:$lineIndex';

  /// Find the next line that contains the detected chord and scroll to it
  void _autoScrollToChord(String detectedChord, Song song) {
    if (detectedChord.isEmpty || detectedChord == _lastScrolledChord) return;
    _lastScrolledChord = detectedChord;

    // Find the first visible line with this chord that's below current scroll
    for (int s = 0; s < song.sections.length; s++) {
      final section = song.sections[s];
      for (int l = 0; l < section.lines.length; l++) {
        final line = section.lines[l];
        final hasChord = line.chords.any((c) =>
            c.display.toLowerCase() == detectedChord.toLowerCase());
        if (!hasChord) continue;

        final keyId = _lineKeyId(s, l);
        final key = _lineKeys[keyId];
        if (key?.currentContext == null) continue;

        final renderBox =
            key!.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox == null) continue;

        // Get position relative to the scroll view
        final scrollBox =
            _scrollController.position.context.storageContext
                .findRenderObject() as RenderBox?;
        if (scrollBox == null) continue;

        final pos = renderBox.localToGlobal(Offset.zero, ancestor: scrollBox);

        // Only scroll if the line is below the visible area or close to bottom
        final viewportHeight = _scrollController.position.viewportDimension;
        if (pos.dy > viewportHeight * 0.4 || pos.dy < 0) {
          final targetOffset = _scrollController.offset + pos.dy - 120;
          _scrollController.animateTo(
            targetOffset.clamp(
                0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final songAsync = ref.watch(transposedSongProvider(widget.songUrl));
    final transpose = ref.watch(transposeProvider);
    final audioState = ref.watch(audioProvider);
    final theme = Theme.of(context);

    final displayTitle = songAsync.value?.title ?? widget.title;
    final displayArtist = songAsync.value?.artist ?? widget.artist;
    final songId = songAsync.value?.id ?? '';

    // Auto-scroll when chord changes
    if (audioState.isListening &&
        audioState.detectedChord.isNotEmpty &&
        songAsync.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoScrollToChord(audioState.detectedChord, songAsync.value!);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(displayTitle,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            if (displayArtist.isNotEmpty)
              Text(displayArtist,
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant)),
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
                  Icon(Icons.error_outline,
                      size: 48, color: theme.colorScheme.error),
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
                    onPressed: () =>
                        ref.invalidate(currentSongProvider(widget.songUrl)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        AsyncValue(:final value?) => Stack(
            children: [
              Column(
                children: [
                  _buildToolbar(theme, transpose),
                  Expanded(
                    child: _buildSongContent(value, audioState),
                  ),
                ],
              ),
              // Chord detector overlay — bottom-right, ignores taps on empty space
              Positioned(
                bottom: 0,
                right: 0,
                child: ChordDetectorOverlay(
                  detectedChord: audioState.detectedChord,
                  confidence: audioState.confidence,
                  isListening: audioState.isListening,
                  onToggle: () =>
                      ref.read(audioProvider.notifier).toggle(),
                ),
              ),
            ],
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildSongContent(Song song, AudioState audioState) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        left: DesignTokens.spacingMd,
        right: DesignTokens.spacingMd,
        top: DesignTokens.spacingMd,
        bottom: 100, // Space for the overlay
      ),
      itemCount: song.sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = song.sections[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.label.isNotEmpty) SectionHeader(section: section),
            ...List.generate(section.lines.length, (lineIndex) {
              final line = section.lines[lineIndex];
              final keyId = _lineKeyId(sectionIndex, lineIndex);
              _lineKeys.putIfAbsent(keyId, () => GlobalKey());

              return KeyedSubtree(
                key: _lineKeys[keyId],
                child: ChordLineWidget(
                  line: line,
                  fontSize: _fontSize,
                  activeChord: audioState.isListening
                      ? audioState.detectedChord
                      : null,
                ),
              );
            }),
            if (sectionIndex < song.sections.length - 1)
              const SizedBox(height: 8),
          ],
        );
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
            onPressed: () =>
                ref.read(transposeProvider.notifier).decrement(),
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
            onPressed: () =>
                ref.read(transposeProvider.notifier).increment(),
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Transpose up',
            visualDensity: VisualDensity.compact,
          ),
          if (transpose != 0)
            TextButton(
              onPressed: () =>
                  ref.read(transposeProvider.notifier).reset(),
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: const Text('Reset', style: TextStyle(fontSize: 12)),
            ),
          const Spacer(),
          // Font size controls
          IconButton(
            onPressed:
                _fontSize > 12 ? () => setState(() => _fontSize -= 2) : null,
            icon: const Icon(Icons.text_decrease, size: 18),
            tooltip: 'Smaller text',
            visualDensity: VisualDensity.compact,
          ),
          Text('${_fontSize.toInt()}',
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          IconButton(
            onPressed:
                _fontSize < 24 ? () => setState(() => _fontSize += 2) : null,
            icon: const Icon(Icons.text_increase, size: 18),
            tooltip: 'Larger text',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

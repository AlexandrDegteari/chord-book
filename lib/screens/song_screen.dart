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

/// A position in the flat chord sequence: section, line, chord index.
class _ChordPosition {
  final int section;
  final int line;
  final int chord;
  final String root; // Normalized root note (e.g. "A", "C#")

  const _ChordPosition({
    required this.section,
    required this.line,
    required this.chord,
    required this.root,
  });
}

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
  final Map<String, GlobalKey> _lineKeys = {};

  // Linear chord progression
  List<_ChordPosition> _chordSequence = [];
  int _currentChordIndex = 0;
  String _lastAdvancedNote = '';

  @override
  void initState() {
    super.initState();
    // Listen to audio state changes outside of build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AudioState>(audioProvider, (prev, next) {
        if (next.isListening && next.detectedNote.isNotEmpty) {
          _onNoteDetected(next.detectedNote);
        }
      });
    });
  }

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

  String _lineKeyId(int s, int l) => '$s:$l';

  /// Build a flat ordered list of all chord positions in the song.
  void _buildChordSequence(Song song) {
    final seq = <_ChordPosition>[];
    for (int s = 0; s < song.sections.length; s++) {
      for (int l = 0; l < song.sections[s].lines.length; l++) {
        final chords = song.sections[s].lines[l].chords;
        for (int c = 0; c < chords.length; c++) {
          seq.add(_ChordPosition(
            section: s,
            line: l,
            chord: c,
            root: _normalizeNote(chords[c].root),
          ));
        }
      }
    }
    _chordSequence = seq;
  }

  /// Normalize note names: Db→C#, Eb→D#, etc.
  String _normalizeNote(String note) {
    const flatToSharp = {
      'Db': 'C#', 'Eb': 'D#', 'Fb': 'E', 'Gb': 'F#',
      'Ab': 'G#', 'Bb': 'A#', 'Cb': 'B',
    };
    return flatToSharp[note] ?? note;
  }

  /// Advance when detected note matches the current expected chord root.
  void _onNoteDetected(String detectedNote) {
    if (detectedNote.isEmpty) return;
    if (_chordSequence.isEmpty) return;
    if (_currentChordIndex >= _chordSequence.length) return;

    final normalized = _normalizeNote(detectedNote);

    // Don't re-trigger on the same note continuously
    if (normalized == _lastAdvancedNote) return;

    final current = _chordSequence[_currentChordIndex];
    if (normalized == current.root) {
      _lastAdvancedNote = normalized;
      setState(() {
        _currentChordIndex++;
      });
      // Scroll to the current chord's line
      if (_currentChordIndex < _chordSequence.length) {
        final next = _chordSequence[_currentChordIndex];
        _scrollToLine(next.section, next.line);
      }
    }
  }

  void _scrollToLine(int s, int l) {
    final keyId = _lineKeyId(s, l);
    final key = _lineKeys[keyId];
    if (key?.currentContext == null) return;

    final renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final scrollRenderBox = _scrollController.position.context.storageContext
        .findRenderObject() as RenderBox?;
    if (scrollRenderBox == null) return;

    final pos =
        renderBox.localToGlobal(Offset.zero, ancestor: scrollRenderBox);
    final viewportHeight = _scrollController.position.viewportDimension;

    if (pos.dy > viewportHeight * 0.6 || pos.dy < viewportHeight * 0.2) {
      final target = _scrollController.offset + pos.dy - viewportHeight * 0.35;
      _scrollController.animateTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Get the set of active chord display names for a given line.
  /// Returns (currentChords, nextChords) — sets of chord display strings.
  ({Set<String> current, Set<String> next}) _getLineHighlights(
      int sectionIdx, int lineIdx) {
    final currentSet = <String>{};
    final nextSet = <String>{};

    if (_chordSequence.isEmpty) return (current: currentSet, next: nextSet);

    // Current chord (the one being played)
    final curIdx = _currentChordIndex > 0 ? _currentChordIndex - 1 : -1;
    if (curIdx >= 0 && curIdx < _chordSequence.length) {
      final pos = _chordSequence[curIdx];
      if (pos.section == sectionIdx && pos.line == lineIdx) {
        // Get the display name from the song data
        currentSet.add('$sectionIdx:$lineIdx:${pos.chord}');
      }
    }

    // Next chord (on deck)
    if (_currentChordIndex < _chordSequence.length) {
      final pos = _chordSequence[_currentChordIndex];
      if (pos.section == sectionIdx && pos.line == lineIdx) {
        nextSet.add('$sectionIdx:$lineIdx:${pos.chord}');
      }
    }

    return (current: currentSet, next: nextSet);
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

    // Build chord sequence when song loads (synchronous, no setState needed)
    if (songAsync.value != null && _chordSequence.isEmpty) {
      _buildChordSequence(songAsync.value!);
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
                  Expanded(child: _buildSongContent(value, audioState)),
                ],
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: ChordDetectorOverlay(
                  detectedNote: audioState.detectedNote,
                  frequency: audioState.frequency,
                  isListening: audioState.isListening,
                  error: audioState.error,
                  onToggle: () {
                    ref.read(audioProvider.notifier).toggle();
                    // Reset progression when toggling
                    setState(() {
                      _currentChordIndex = 0;
                      _lastAdvancedNote = '';
                    });
                  },
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
        bottom: 100,
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

              // Get highlights for this line
              final highlights = audioState.isListening
                  ? _getLineHighlights(sectionIndex, lineIndex)
                  : (current: <String>{}, next: <String>{});

              return KeyedSubtree(
                key: _lineKeys[keyId],
                child: ChordLineWidget(
                  line: line,
                  fontSize: _fontSize,
                  sectionIndex: sectionIndex,
                  lineIndex: lineIndex,
                  currentChordKeys: highlights.current,
                  nextChordKeys: highlights.next,
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

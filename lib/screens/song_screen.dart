import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/generated/app_localizations.dart';
import '../config/design_tokens.dart';
import '../models/search_result.dart';
import '../models/song.dart';
import '../providers/audio_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/song_provider.dart';
import '../providers/song_settings_provider.dart';
import '../utils/chord_utils.dart';
import '../widgets/chord_diagram.dart';
import '../widgets/chord_line.dart';
import '../widgets/section_header.dart';
import '../widgets/tuner_bottom_sheet.dart';

class _ChordPosition {
  final int section;
  final int line;
  final int chord;
  final String root;

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

  List<_ChordPosition> _chordSequence = [];
  int _currentChordIndex = 0;
  bool _canAdvance = true;
  Timer? _cooldownTimer;
  String _lastSongId = '';

  // Local session state — initialized from defaults, not persisted
  bool _autoScroll = true;
  bool _showDetectedChord = true;
  bool _showChordDiagram = false;
  bool _defaultsLoaded = false;

  static const _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _scrollController.dispose();
    Future.microtask(() {
      ref.read(transposeProvider.notifier).reset();
      ref.read(audioProvider.notifier).stopListening();
    });
    super.dispose();
  }

  String _lineKeyId(int s, int l) => '$s:$l';

  int _noteToIndex(String note) {
    const flatToSharp = {
      'Db': 'C#', 'Eb': 'D#', 'Fb': 'E', 'Gb': 'F#',
      'Ab': 'G#', 'Bb': 'A#', 'Cb': 'B',
    };
    final normalized = flatToSharp[note] ?? note;
    final idx = _noteNames.indexOf(normalized);
    return idx >= 0 ? idx : 0;
  }

  void _rebuildChordSequence(Song song, int transpose) {
    final key = '${song.id}_$transpose';
    if (_lastSongId == key) return;
    _lastSongId = key;

    final seq = <_ChordPosition>[];
    for (int s = 0; s < song.sections.length; s++) {
      for (int l = 0; l < song.sections[s].lines.length; l++) {
        final chords = song.sections[s].lines[l].chords;
        for (int c = 0; c < chords.length; c++) {
          seq.add(_ChordPosition(
            section: s, line: l, chord: c, root: chords[c].root,
          ));
        }
      }
    }
    _chordSequence = seq;
    _currentChordIndex = 0;
    _canAdvance = true;
  }

  void _onNoteDetected(String detectedNote) {
    if (detectedNote.isEmpty) return;
    if (_chordSequence.isEmpty) return;
    if (_currentChordIndex >= _chordSequence.length) return;
    if (!_canAdvance) return;

    final expected = _chordSequence[_currentChordIndex];
    final expectedRoot = _noteToIndex(expected.root);
    final detectedRoot = _noteToIndex(detectedNote);

    if (detectedRoot == expectedRoot) {
      _canAdvance = false;
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer(const Duration(milliseconds: 600), () {
        _canAdvance = true;
      });

      setState(() => _currentChordIndex++);

      if (_autoScroll && _currentChordIndex < _chordSequence.length) {
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

    final pos = renderBox.localToGlobal(Offset.zero, ancestor: scrollRenderBox);
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

  String? _currentSongChordDisplay(Song song) {
    if (_chordSequence.isEmpty || _currentChordIndex >= _chordSequence.length) return null;
    final pos = _chordSequence[_currentChordIndex];
    if (pos.section < song.sections.length) {
      final section = song.sections[pos.section];
      if (pos.line < section.lines.length) {
        final line = section.lines[pos.line];
        if (pos.chord < line.chords.length) return line.chords[pos.chord].display;
      }
    }
    return null;
  }

  (int section, int line)? get _activeLine {
    if (_chordSequence.isEmpty || _currentChordIndex >= _chordSequence.length) return null;
    final pos = _chordSequence[_currentChordIndex];
    return (pos.section, pos.line);
  }

  ({Set<String> current, Set<String> next}) _getLineHighlights(int sectionIdx, int lineIdx) {
    final currentSet = <String>{};
    final nextSet = <String>{};
    if (_chordSequence.isEmpty) return (current: currentSet, next: nextSet);

    final curIdx = _currentChordIndex > 0 ? _currentChordIndex - 1 : -1;
    if (curIdx >= 0 && curIdx < _chordSequence.length) {
      final pos = _chordSequence[curIdx];
      if (pos.section == sectionIdx && pos.line == lineIdx) {
        currentSet.add('$sectionIdx:$lineIdx:${pos.chord}');
      }
    }
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
    final defaults = ref.watch(songSettingsProvider);
    final theme = Theme.of(context);

    // Load defaults once when opening a song
    if (!_defaultsLoaded) {
      _autoScroll = defaults.autoScrollEnabled;
      _showDetectedChord = defaults.showDetectedChord;
      _showChordDiagram = defaults.showChordDiagram;
      _defaultsLoaded = true;
    }

    final displayTitle = songAsync.value?.title ?? widget.title;
    final displayArtist = songAsync.value?.artist ?? widget.artist;
    final songId = songAsync.value?.id ?? '';
    final currentChord = songAsync.value != null ? _currentSongChordDisplay(songAsync.value!) : null;

    if (songAsync.value != null) {
      _rebuildChordSequence(songAsync.value!, transpose);
    }

    ref.listen<AudioState>(audioProvider, (prev, next) {
      if (!mounted) return;
      if (next.isListening && next.detectedNote.isNotEmpty) {
        if (prev?.detectedNote != next.detectedNote) {
          _onNoteDetected(next.detectedNote);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(displayTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (displayArtist.isNotEmpty)
              Text(displayArtist, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          if (songId.isNotEmpty)
            Builder(builder: (context) {
              final favs = ref.watch(favoritesProvider);
              final isFav = favs.any((f) => f.id == songId);
              return IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : null, size: 20),
                onPressed: () {
                  final song = songAsync.value!;
                  ref.read(favoritesProvider.notifier).toggle(SearchResult(
                    id: song.id, title: song.title,
                    artist: song.artist, url: widget.songUrl,
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
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: DesignTokens.spacingSm),
                  Text(AppLocalizations.of(context)!.failedToLoadSong,
                      style: TextStyle(fontSize: 16, color: theme.colorScheme.error)),
                  const SizedBox(height: DesignTokens.spacingXs),
                  Text('$error', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: DesignTokens.spacingMd),
                  FilledButton.icon(
                    onPressed: () => ref.invalidate(currentSongProvider(widget.songUrl)),
                    icon: const Icon(Icons.refresh), label: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            ),
          ),
        AsyncValue(:final value?) => Stack(
            children: [
              Column(
                children: [
                  _buildToolbar(theme, transpose, audioState),
                  Expanded(child: _buildSongContent(value, audioState)),
                ],
              ),
              // Detected chord badge — bottom right
              if (_showDetectedChord && audioState.isListening && audioState.detectedChord.isNotEmpty)
                Positioned(
                  bottom: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note, color: theme.colorScheme.onPrimaryContainer, size: 20),
                        const SizedBox(width: 6),
                        Text(audioState.detectedChord, style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace',
                          color: theme.colorScheme.onPrimaryContainer,
                        )),
                      ],
                    ),
                  ),
                ),
              // Chord diagram — bottom right, above detected chord
              if (_showChordDiagram && currentChord != null && currentChord.isNotEmpty)
                Positioned(
                  bottom: _showDetectedChord && audioState.isListening && audioState.detectedChord.isNotEmpty ? 72 : 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: ChordDiagram(chordName: currentChord, size: 140),
                  ),
                ),
            ],
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildSongContent(Song song, AudioState audioState) {
    final active = audioState.isListening && _autoScroll ? _activeLine : null;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        left: DesignTokens.spacingMd, right: DesignTokens.spacingMd,
        top: DesignTokens.spacingMd, bottom: 100,
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

              final highlights = audioState.isListening
                  ? _getLineHighlights(sectionIndex, lineIndex)
                  : (current: <String>{}, next: <String>{});

              final isActiveLine = active != null &&
                  active.$1 == sectionIndex && active.$2 == lineIndex;

              return KeyedSubtree(
                key: _lineKeys[keyId],
                child: ChordLineWidget(
                  line: line, fontSize: _fontSize,
                  sectionIndex: sectionIndex, lineIndex: lineIndex,
                  currentChordKeys: highlights.current,
                  nextChordKeys: highlights.next,
                  isActiveLine: isActiveLine,
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

  Widget _buildToolbar(ThemeData theme, int transpose, AudioState audioState) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSm, vertical: DesignTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          // Transpose
          IconButton(
            onPressed: () => ref.read(transposeProvider.notifier).decrement(),
            icon: const Icon(Icons.remove, size: 18),
            tooltip: l10n.transposeDown, visualDensity: VisualDensity.compact,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 28),
            alignment: Alignment.center,
            child: Text(
              ChordUtils.formatTranspose(transpose),
              style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace',
                color: transpose != 0 ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: () => ref.read(transposeProvider.notifier).increment(),
            icon: const Icon(Icons.add, size: 18),
            tooltip: l10n.transposeUp, visualDensity: VisualDensity.compact,
          ),
          if (transpose != 0)
            TextButton(
              onPressed: () => ref.read(transposeProvider.notifier).reset(),
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4)),
              child: Text(l10n.reset, style: const TextStyle(fontSize: 11)),
            ),
          const Spacer(),
          // Tuner
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context, isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const TunerBottomSheet(),
            ),
            icon: const Icon(Icons.tune, size: 18),
            tooltip: l10n.tuner, visualDensity: VisualDensity.compact,
          ),
          // Chord diagram
          IconButton(
            onPressed: () => setState(() => _showChordDiagram = !_showChordDiagram),
            icon: Icon(Icons.grid_on, size: 18,
              color: _showChordDiagram ? theme.colorScheme.primary : null),
            tooltip: l10n.chordDiagram, visualDensity: VisualDensity.compact,
          ),
          // Detected chord
          IconButton(
            onPressed: () => setState(() => _showDetectedChord = !_showDetectedChord),
            icon: Icon(Icons.music_note, size: 18,
              color: _showDetectedChord ? theme.colorScheme.primary : null),
            tooltip: l10n.detectedChord, visualDensity: VisualDensity.compact,
          ),
          // Mic
          IconButton(
            onPressed: () {
              ref.read(audioProvider.notifier).toggle();
              setState(() { _currentChordIndex = 0; _canAdvance = true; });
              _cooldownTimer?.cancel();
            },
            icon: Icon(
              audioState.isListening ? Icons.mic : Icons.mic_none, size: 18,
              color: audioState.isListening ? theme.colorScheme.error : null),
            tooltip: audioState.isListening ? l10n.stop : l10n.listen,
            visualDensity: VisualDensity.compact,
          ),
          // Font size
          IconButton(
            onPressed: _fontSize > 12 ? () => setState(() => _fontSize -= 2) : null,
            icon: const Icon(Icons.text_decrease, size: 18),
            tooltip: l10n.smallerText, visualDensity: VisualDensity.compact,
          ),
          Text('${_fontSize.toInt()}',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          IconButton(
            onPressed: _fontSize < 24 ? () => setState(() => _fontSize += 2) : null,
            icon: const Icon(Icons.text_increase, size: 18),
            tooltip: l10n.largerText, visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

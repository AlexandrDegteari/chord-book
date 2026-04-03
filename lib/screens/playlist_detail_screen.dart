import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../config/design_tokens.dart';
import '../models/search_result.dart';
import '../providers/favorites_provider.dart';
import '../providers/playlists_provider.dart';
import '../providers/recent_provider.dart';
import '../services/database_helper.dart';
import '../widgets/song_card.dart';
import '../widgets/add_to_playlist_sheet.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  final _db = DatabaseHelper();
  List<SearchResult>? _songs;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await _db.getPlaylistSongs(widget.playlistId);
    if (mounted) setState(() => _songs = songs);
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
    final playlists = ref.watch(playlistsProvider);
    final playlist = playlists.where((p) => p.id == widget.playlistId).firstOrNull;

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editPlaylist(playlist.title, playlist.description),
          ),
        ],
      ),
      body: _songs == null
          ? const Center(child: CircularProgressIndicator())
          : _songs!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.queue_music, size: 64,
                          color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: DesignTokens.spacingMd),
                      Text(l10n.emptyPlaylist,
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _songs!.length,
                  itemBuilder: (context, index) {
                    final song = _songs![index];
                    final isFav = ref.watch(favoritesProvider)
                        .any((f) => f.id == song.id);
                    return Dismissible(
                      key: ValueKey('ps_${song.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(
                            right: DesignTokens.spacingMd),
                        margin: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingMd,
                          vertical: DesignTokens.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await _db.removeSongFromPlaylist(
                            widget.playlistId, song.id);
                        ref.read(playlistsProvider.notifier).refresh();
                        _loadSongs();
                      },
                      child: SongCard(
                        result: song,
                        isFavorite: isFav,
                        onFavoriteToggle: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (_) => AddToPlaylistSheet(song: song),
                          );
                        },
                        onTap: () => _navigateToSong(song),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _editPlaylist(String currentTitle, String? currentDesc) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: currentTitle);
    final descController = TextEditingController(text: currentDesc ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editSong),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: l10n.playlistTitle),
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: l10n.playlistDescription),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (result == true) {
      final title = titleController.text.trim();
      if (title.isNotEmpty) {
        await ref.read(playlistsProvider.notifier).update(
          widget.playlistId,
          title: title,
          description: descController.text.trim(),
        );
      }
    }
  }
}

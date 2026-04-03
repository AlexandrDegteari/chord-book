import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/generated/app_localizations.dart';
import '../config/design_tokens.dart';
import '../models/search_result.dart';
import '../providers/favorites_provider.dart';
import '../providers/playlists_provider.dart';
import '../services/database_helper.dart';

class AddToPlaylistSheet extends ConsumerStatefulWidget {
  final SearchResult song;

  const AddToPlaylistSheet({super.key, required this.song});

  @override
  ConsumerState<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<AddToPlaylistSheet> {
  final _db = DatabaseHelper();

  Future<void> _toggleFavorite() async {
    ref.read(favoritesProvider.notifier).toggle(widget.song);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addToPlaylist(String playlistId) async {
    await _db.addSongToPlaylist(playlistId, widget.song);
    ref.invalidate(playlistSongsProvider(playlistId));
    ref.read(playlistsProvider.notifier).refresh();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _createAndAdd() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createPlaylist),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.playlistTitle),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      final playlist = await ref.read(playlistsProvider.notifier).create(title);
      await _addToPlaylist(playlist.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final playlists = ref.watch(playlistsProvider);
    final isFav = ref.watch(favoritesProvider).any((f) => f.id == widget.song.id);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: DesignTokens.spacingSm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            child: Text(l10n.addToPlaylist,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
          ),

          // Favorites option
          ListTile(
            leading: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : null,
            ),
            title: Text(l10n.addToFavorites),
            trailing: isFav ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
            onTap: _toggleFavorite,
          ),

          const Divider(height: 1),

          // Existing playlists
          if (playlists.isNotEmpty) ...[
            ...playlists.map((playlist) => FutureBuilder<List<String>>(
              future: _db.getPlaylistIdsForSong(widget.song.id),
              builder: (context, snapshot) {
                final isInPlaylist = snapshot.data?.contains(playlist.id) ?? false;
                return ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: Text(playlist.title),
                  subtitle: Text(l10n.nSongs(playlist.songCount)),
                  trailing: isInPlaylist
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: isInPlaylist ? null : () => _addToPlaylist(playlist.id),
                );
              },
            )),
          ],

          // Create new playlist
          ListTile(
            leading: Icon(Icons.add, color: theme.colorScheme.primary),
            title: Text(l10n.newPlaylist,
                style: TextStyle(color: theme.colorScheme.primary)),
            onTap: _createAndAdd,
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + DesignTokens.spacingSm),
        ],
      ),
    );
  }
}

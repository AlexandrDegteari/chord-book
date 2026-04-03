import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../config/design_tokens.dart';
import '../models/playlist.dart';
import '../models/user_song.dart';
import '../providers/playlists_provider.dart';
import '../providers/user_songs_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myLibrary),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.playlists),
            Tab(text: l10n.mySongs),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PlaylistsTab(),
          _MySongsTab(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) => FloatingActionButton(
          onPressed: () {
            if (_tabController.index == 0) {
              _createPlaylist();
            } else {
              context.push('/song-editor');
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _createPlaylist() async {
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
      await ref.read(playlistsProvider.notifier).create(title);
    }
  }
}

class _PlaylistsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final playlists = ref.watch(playlistsProvider);

    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_music, size: 64,
                color: theme.colorScheme.outlineVariant),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(l10n.noPlaylists,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Dismissible(
          key: ValueKey('playlist_${playlist.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: DesignTokens.spacingMd),
            margin: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingXs,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: const Icon(Icons.close, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, l10n),
          onDismissed: (_) {
            ref.read(playlistsProvider.notifier).delete(playlist.id);
          },
          child: _PlaylistTile(playlist: playlist),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePlaylist),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ) ?? false;
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingXs,
      ),
      child: ListTile(
        leading: Icon(Icons.queue_music, color: theme.colorScheme.primary),
        title: Text(playlist.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(l10n.nSongs(playlist.songCount)),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        onTap: () => context.push('/playlist/${playlist.id}'),
      ),
    );
  }
}

class _MySongsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final songs = ref.watch(userSongsProvider);

    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note, size: 64,
                color: theme.colorScheme.outlineVariant),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(l10n.noMySongs,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return Dismissible(
          key: ValueKey('usong_${song.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: DesignTokens.spacingMd),
            margin: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingXs,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: const Icon(Icons.close, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, l10n),
          onDismissed: (_) {
            ref.read(userSongsProvider.notifier).delete(song.id);
          },
          child: _UserSongTile(song: song),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSong),
        content: Text(l10n.confirmDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ) ?? false;
  }
}

class _UserSongTile extends StatelessWidget {
  final UserSong song;

  const _UserSongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final statusLabel = switch (song.status) {
      'draft' => l10n.draft,
      'submitted' => l10n.submitted,
      'approved' => l10n.approved,
      'rejected' => l10n.rejected,
      _ => song.status,
    };

    final statusColor = switch (song.status) {
      'draft' => theme.colorScheme.outline,
      'submitted' => Colors.orange,
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => theme.colorScheme.outline,
    };

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingXs,
      ),
      child: ListTile(
        leading: Icon(Icons.edit_note, color: theme.colorScheme.primary),
        title: Text(song.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Flexible(child: Text(song.artist, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(statusLabel,
                  style: TextStyle(fontSize: 11, color: statusColor,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        onTap: () => context.push('/song-editor?id=${song.id}'),
      ),
    );
  }
}

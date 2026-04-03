import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../config/design_tokens.dart';
import '../models/user_song.dart';
import '../providers/user_songs_provider.dart';
import '../services/database_helper.dart';

class SongEditorScreen extends ConsumerStatefulWidget {
  final String? songId;
  final String? originalSongId;
  final String? initialTitle;
  final String? initialArtist;

  const SongEditorScreen({
    super.key,
    this.songId,
    this.originalSongId,
    this.initialTitle,
    this.initialArtist,
  });

  @override
  ConsumerState<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends ConsumerState<SongEditorScreen> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final List<_SectionData> _sections = [];
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.songId != null) {
      // Editing existing user song
      final db = DatabaseHelper();
      final row = await db.getUserSong(widget.songId!);
      if (row != null) {
        final song = UserSong.fromDb(row);
        _titleController.text = song.title;
        _artistController.text = song.artist;
        _sections.addAll(song.sections.map((s) => _SectionData(
          type: s.type,
          controller: TextEditingController(text: s.content),
        )));
        _isEditing = true;
      }
    } else {
      // New song
      _titleController.text = widget.initialTitle ?? '';
      _artistController.text = widget.initialArtist ?? '';
      if (_sections.isEmpty) {
        _sections.add(_SectionData(
          type: 'verse',
          controller: TextEditingController(),
        ));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    for (final s in _sections) {
      s.controller.dispose();
    }
    super.dispose();
  }

  List<SongSection> _buildSections() {
    return _sections
        .where((s) => s.controller.text.trim().isNotEmpty)
        .map((s) => SongSection(type: s.type, content: s.controller.text.trim()))
        .toList();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    if (title.isEmpty || artist.isEmpty) return;

    final sections = _buildSections();
    if (sections.isEmpty) return;

    if (_isEditing && widget.songId != null) {
      await ref.read(userSongsProvider.notifier).update(
        widget.songId!,
        title: title,
        artist: artist,
        sections: sections,
      );
    } else {
      await ref.read(userSongsProvider.notifier).create(
        title: title,
        artist: artist,
        sections: sections,
        originalSongId: widget.originalSongId,
      );
    }

    if (mounted) context.pop();
  }

  Future<void> _submit() async {
    if (!_isEditing || widget.songId == null) {
      // Save first, then submit
      await _save();
      return;
    }
    await _save();
    await ref.read(userSongsProvider.notifier).submit(widget.songId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? l10n.editSong : l10n.createSong)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editSong : l10n.createSong),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.saveDraft),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              children: [
                // Title
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.songTitle,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingSm),

                // Artist
                TextField(
                  controller: _artistController,
                  decoration: InputDecoration(
                    labelText: l10n.songArtist,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingMd),

                // Sections
                ...List.generate(_sections.length, (index) {
                  final section = _sections[index];
                  return _buildSectionCard(section, index, l10n, theme);
                }),

                // Add section button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _sections.add(_SectionData(
                          type: 'verse',
                          controller: TextEditingController(),
                        ));
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addSection),
                  ),
                ),
              ],
            ),
          ),

          // Bottom bar
          Container(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.spacingMd,
              DesignTokens.spacingSm,
              DesignTokens.spacingMd,
              MediaQuery.of(context).padding.bottom + DesignTokens.spacingSm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _save,
                    child: Text(l10n.saveDraft),
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingSm),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(l10n.submitForReview),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      _SectionData section, int index, AppLocalizations l10n, ThemeData theme) {
    final sectionTypes = {
      'verse': l10n.verse,
      'chorus': l10n.chorus,
      'bridge': l10n.bridge,
      'intro': l10n.intro,
      'outro': l10n.outro,
      'solo': l10n.solo,
      'other': l10n.other,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: section.type,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: sectionTypes.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => section.type = value);
                      }
                    },
                  ),
                ),
                if (_sections.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _sections[index].controller.dispose();
                        _sections.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingXs),
            TextField(
              controller: section.controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: l10n.songContent,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionData {
  String type;
  final TextEditingController controller;

  _SectionData({required this.type, required this.controller});
}

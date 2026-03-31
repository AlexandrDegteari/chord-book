import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/song_settings_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeProvider);
    final songSettings = ref.watch(songSettingsProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          _SectionTitle(l10n.appearance),
          ...ThemeMode.values.map((mode) => ListTile(
                leading: Icon(
                  switch (mode) {
                    ThemeMode.system => Icons.brightness_auto,
                    ThemeMode.light => Icons.light_mode,
                    ThemeMode.dark => Icons.dark_mode,
                  },
                ),
                title: Text(switch (mode) {
                  ThemeMode.system => l10n.systemTheme,
                  ThemeMode.light => l10n.lightTheme,
                  ThemeMode.dark => l10n.darkTheme,
                }),
                trailing: themeMode == mode
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
              )),
          const Divider(),
          _SectionTitle(l10n.language),
          ..._buildLanguageOptions(context, ref, l10n, currentLocale),
          const Divider(),
          _SectionTitle(l10n.songScreenDefaults),
          SwitchListTile(
            secondary: const Icon(Icons.swap_vert),
            title: Text(l10n.autoScroll),
            subtitle: Text(l10n.autoScrollSubtitle),
            value: songSettings.autoScrollEnabled,
            onChanged: (_) => ref.read(songSettingsProvider.notifier).toggleAutoScroll(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.music_note),
            title: Text(l10n.detectedChord),
            subtitle: Text(l10n.showDetectedChordBadge),
            value: songSettings.showDetectedChord,
            onChanged: (_) => ref.read(songSettingsProvider.notifier).toggleDetectedChord(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.grid_on),
            title: Text(l10n.chordDiagram),
            subtitle: Text(l10n.showFingeringDiagram),
            value: songSettings.showChordDiagram,
            onChanged: (_) => ref.read(songSettingsProvider.notifier).toggleChordDiagram(),
          ),
          const Divider(),
          _SectionTitle(l10n.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appTitle),
            subtitle: Text(l10n.versionInfo('1.0.0')),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildLanguageOptions(
      BuildContext context, WidgetRef ref, AppLocalizations l10n, Locale? currentLocale) {
    final options = <(Locale?, String, String)>[
      (null, l10n.systemLanguage, ''),
      (const Locale('en'), l10n.english, '🇺🇸'),
      (const Locale('ru'), l10n.russian, '🇷🇺'),
      (const Locale('ro'), l10n.romanian, '🇷🇴'),
    ];

    return options.map((option) {
      final (locale, label, flag) = option;
      final isSelected = currentLocale?.languageCode == locale?.languageCode;
      return ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 24)),
        title: Text(label),
        trailing: isSelected
            ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: () => ref.read(localeProvider.notifier).setLocale(locale),
      );
    }).toList();
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

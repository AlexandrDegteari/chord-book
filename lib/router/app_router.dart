import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/song_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/metronome_screen.dart';
import '../screens/tuner_screen.dart';
import '../widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        // Tab 0: Book
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 1: Tuner
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tuner',
              builder: (context, state) => const TunerScreen(),
            ),
          ],
        ),
        // Tab 2: Metronome
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/metronome',
              builder: (context, state) => const MetronomeScreen(),
            ),
          ],
        ),
        // Tab 3: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    // Song screen is outside the shell (full screen, no tab bar)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/song',
      builder: (context, state) {
        final url = state.uri.queryParameters['url'] ?? '';
        final title = state.uri.queryParameters['title'] ?? '';
        final artist = state.uri.queryParameters['artist'] ?? '';
        return SongScreen(songUrl: url, title: title, artist: artist);
      },
    ),
  ],
);

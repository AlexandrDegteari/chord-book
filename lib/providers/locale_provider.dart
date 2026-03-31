import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  static const _key = 'app_locale';

  @override
  Locale? build() {
    Future.microtask(() => _load());
    return null; // null = system default
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, locale.languageCode);
    }
  }
}

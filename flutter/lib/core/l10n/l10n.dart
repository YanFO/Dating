import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/providers/core_providers.dart';
import 'app_locale.dart';
import 'strings_en.dart';
import 'strings_zh_tw.dart';

const _kLocaleKey = 'app_locale';

class LocaleNotifier extends StateNotifier<AppLocale> {
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs) : super(_loadSaved(_prefs));

  static AppLocale _loadSaved(SharedPreferences prefs) {
    final code = prefs.getString(_kLocaleKey);
    return AppLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLocale.en,
    );
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    await _prefs.setString(_kLocaleKey, locale.code);
  }

  void toggle() {
    setLocale(state == AppLocale.en ? AppLocale.zhTW : AppLocale.en);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

final stringsProvider = Provider<Map<String, String>>((ref) {
  final locale = ref.watch(localeProvider);
  switch (locale) {
    case AppLocale.en:
      return stringsEn;
    case AppLocale.zhTW:
      return stringsZhTw;
  }
});

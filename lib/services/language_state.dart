import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages the app supports.
enum AppLanguage { english, malay, chinese }

extension AppLanguageInfo on AppLanguage {
  /// Short code, also used to save the choice on the phone.
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.malay:
        return 'ms';
      case AppLanguage.chinese:
        return 'zh';
    }
  }

  /// Name written in the language itself (shown in the picker).
  String get nativeName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.malay:
        return 'Bahasa Melayu';
      case AppLanguage.chinese:
        return '中文 (简体)';
    }
  }

  /// English name (shown as a small hint under the native name).
  String get englishName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.malay:
        return 'Malay';
      case AppLanguage.chinese:
        return 'Chinese (Simplified)';
    }
  }

  /// Name used inside AI prompts, e.g. "Write the reply in Bahasa Melayu".
  String get aiName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.malay:
        return 'Bahasa Melayu (Malay)';
      case AppLanguage.chinese:
        return 'Simplified Chinese (简体中文)';
    }
  }

  /// For the full app translation later (Flutter localization).
  Locale get locale => Locale(code);
}

const String _kLanguageKey = 'app_language';

/// The language currently chosen. Screens can listen to this, or read
/// `appLanguageNotifier.value` when they build an AI prompt.
final ValueNotifier<AppLanguage> appLanguageNotifier =
    ValueNotifier<AppLanguage>(AppLanguage.english);

/// Call once at app start (see main.dart) to restore the saved choice.
Future<void> loadSavedLanguage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLanguageKey);
    appLanguageNotifier.value = AppLanguage.values.firstWhere(
      (l) => l.code == saved,
      orElse: () => AppLanguage.english,
    );
  } catch (e) {
    debugPrint('Could not load saved language: $e');
  }
}

/// Changes the language and remembers it for next time.
Future<void> setAppLanguage(AppLanguage language) async {
  appLanguageNotifier.value = language;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, language.code);
  } catch (e) {
    debugPrint('Could not save language: $e');
  }
}
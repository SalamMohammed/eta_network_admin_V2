import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = LocaleProvider();

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Loads the saved locale from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  /// Updates the locale and saves it to SharedPreferences.
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }
}

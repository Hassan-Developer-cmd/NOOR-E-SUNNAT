import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_translations.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_language_code';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool get isUrdu => _locale.languageCode == 'ur';
  TextDirection get textDirection => isUrdu ? TextDirection.rtl : TextDirection.ltr;

  LanguageProvider();

  /// Initialize and load stored language preference from disk.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && (savedCode == 'en' || savedCode == 'ur')) {
        _locale = Locale(savedCode);
        notifyListeners();
      }
    } catch (e) {
      // Fallback to default English
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, languageCode);
    } catch (e) {
      // SharedPreferences error handling
    }
  }

  void toggleLanguage() {
    setLanguage(isUrdu ? 'en' : 'ur');
  }

  /// Translate key according to current active locale.
  String tr(String key) {
    return AppTranslations.get(key, _locale.languageCode);
  }
}

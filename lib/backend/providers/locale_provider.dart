import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void setLocale(Locale locale) async {
    if (!L10n.all.contains(locale)) return;
    
    _locale = locale;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString('locale');
    
    if (localeCode != null) {
      _locale = Locale(localeCode);
      notifyListeners();
    }
  }
}

class L10n {
  static const all = [
    Locale('en'),
    Locale('hi'),
    Locale('bn'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
    Locale('ja'),
    Locale('as'),  // Assamese
    Locale('lus'), // Mizo/Lushai
    Locale('mni'), // Manipuri
    Locale('ne'),  // Nepali
    Locale('fr'),  // French
    Locale('es'),  // Spanish
    Locale('de'),  // German
    Locale('ru'),  // Russian
    Locale('zh'),  // Chinese
  ];

  static String getFlag(String code) {
    switch (code) {
      case 'hi':
      case 'bn':
      case 'kn':
      case 'ml':
      case 'mr':
      case 'ta':
      case 'te':
      case 'as':  // Assamese
      case 'mni': // Manipuri
        return '🇮🇳';
      case 'ja':
        return '🇯🇵 ';
      case 'lus': // Mizo/Lushai (Myanmar origin but spoken in India)
        return '🇮🇳';
      case 'ne':  // Nepali
        return '🇳🇵';
      case 'fr':  // French
        return '🇫🇷';
      case 'es':  // Spanish
        return '🇪🇸';
      case 'de':  // German
        return '🇩🇪';
      case 'ru':  // Russian
        return '🇷🇺';
      case 'zh':  // Chinese
        return '🇨🇳';
      case 'en':
      default:
        return '🇺🇸';
    }
  }

  static String getName(String code) {
    switch (code) {
      case 'hi':
        return 'हिंदी';
      case 'bn':
        return 'বাংলা';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'ml':
        return 'മലയാളം';
      case 'mr':
        return 'मराठी';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'ja':
        return '日本語';
      case 'as':  // Assamese
        return 'অসমীয়া';
      case 'lus': // Mizo/Lushai
        return 'Mizo ṭawng';
      case 'mni': // Manipuri
        return 'ꯃꯤꯇꯩ ꯂꯣꯟ';
      case 'ne':  // Nepali
        return 'नेपाली';
      case 'fr':  // French
        return 'Français';
      case 'es':  // Spanish
        return 'Español';
      case 'de':  // German
        return 'Deutsch';
      case 'ru':  // Russian
        return 'Русский';
      case 'zh':  // Chinese
        return '中文';
      case 'en':
      default:
        return 'English';
    }
  }
}
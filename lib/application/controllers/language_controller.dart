import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modèle représentant une langue sélectionnable dans l'application.
class AppLanguage {
  final String flag;         // emoji drapeau
  final String name;         // nom affiché dans sa propre langue
  final String languageCode;
  final String countryCode;

  const AppLanguage({
    required this.flag,
    required this.name,
    required this.languageCode,
    required this.countryCode,
  });

  Locale get locale => Locale(languageCode, countryCode);

  /// Clé utilisée dans les traductions GetX (ex: 'fr_FR').
  String get translationKey => '${languageCode}_$countryCode';
}

/// GetxController qui gère la locale active et la persiste.
class LanguageController extends GetxController {
  static const _prefKey = 'app_language'; // clé SharedPreferences

  // ── Langues disponibles ───────────────────────────────────────────────────

  static const List<AppLanguage> available = [
    AppLanguage(
      flag:         '🇫🇷',
      name:         'Français',
      languageCode: 'fr',
      countryCode:  'FR',
    ),
    AppLanguage(
      flag:         '🇬🇧',
      name:         'English',
      languageCode: 'en',
      countryCode:  'US',
    ),
    AppLanguage(
      flag:         '🇩🇿',
      name:         'العربية',
      languageCode: 'ar',
      countryCode:  'DZ',
    ),
  ];

  // ── État réactif ──────────────────────────────────────────────────────────

  /// Langue actuellement sélectionnée — Rx<AppLanguage> observé par Obx.
  late final Rx<AppLanguage> current;

  /// Vrai quand l'arabe est actif.
  bool get isRtl => current.value.languageCode == 'ar';

  // ── Cycle de vie ──────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    current = Rx<AppLanguage>(available[0]); // français par défaut
    _loadSaved();
  }

  // ── API publique ──────────────────────────────────────────────────────────

  /// Change la locale de l'app et persiste le choix.
  Future<void> changeLanguage(AppLanguage lang) async {
    current.value = lang;            // déclenche Obx dans main.dart
    Get.updateLocale(lang.locale);   // met à jour toutes les chaînes .tr
    Get.forceAppUpdate();            // force le refresh de toutes les pages ouvertes
    update();                        // rebuild GetBuilder si utilisé

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang.translationKey);
  }

  /// Surcharge pratique avec une clé comme 'ar_DZ'.
  Future<void> changeLanguageByKey(String key) async {
    final lang = available.firstWhere(
      (l) => l.translationKey == key,
      orElse: () => available[0],
    );
    await changeLanguage(lang);
  }

  // ── Helpers privés ────────────────────────────────────────────────────────

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      final lang = available.firstWhere(
        (l) => l.translationKey == saved,
        orElse: () => available[0],
      );
      current.value = lang;
      Get.updateLocale(lang.locale);
      Get.forceAppUpdate();
      update();
    }
  }
}
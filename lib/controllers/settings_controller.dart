import 'dart:ui';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../services/bedtime_reminder_service.dart';

/// Manages app settings: language, sound mode, etc.
class SettingsController extends GetxController {
  static const String _languageKey = 'app_language';
  static const String _soundModeKey = 'sound_mode';
  static const String _bedtimeReminderKey = 'bedtime_reminder_enabled';
  static const String _sleepDurationKey = 'sleep_duration_hours';

  // Observable settings
  final RxString locale = 'ar'.obs; // Arabic by default
  final RxString soundMode = 'adhan_vibrate'.obs; // Default sound mode
  final RxBool isBedtimeReminderEnabled = true.obs;
  final RxInt sleepDurationHours = 7.obs; // 7 hours by default

  // Translations map
  final RxMap<String, dynamic> translations = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  /// Load all settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load language
    locale.value = prefs.getString(_languageKey) ?? 'ar';
    await _loadTranslations(locale.value);

    // Load sound mode
    soundMode.value = prefs.getString(_soundModeKey) ?? 'adhan_vibrate';
    
    // Load bedtime settings
    isBedtimeReminderEnabled.value = prefs.getBool(_bedtimeReminderKey) ?? true;
    sleepDurationHours.value = prefs.getInt(_sleepDurationKey) ?? 7;
  }

  /// Load translation file for given locale
  Future<void> _loadTranslations(String lang) async {
    try {
      final jsonString = await rootBundle.loadString(
        'lib/config/localization/$lang.json',
      );
      translations.value = json.decode(jsonString);
    } catch (e) {
      print('Error loading translations: $e');
      // Fallback to English if Arabic fails
      if (lang == 'ar') {
        await _loadTranslations('en');
      }
    }
  }

  /// Change app language
  Future<void> changeLanguage(String newLocale) async {
    locale.value = newLocale;
    await _loadTranslations(newLocale);

    // Update GetX locale
    final languageCode = newLocale == 'ar' ? 'ar' : 'en';
    final countryCode = newLocale == 'ar' ? 'SA' : 'US';
    Get.updateLocale(Locale(languageCode, countryCode));

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, newLocale);
  }

  /// Change sound mode
  Future<void> changeSoundMode(String mode) async {
    soundMode.value = mode;

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundModeKey, mode);
  }

  /// Toggle bedtime reminder
  Future<void> toggleBedtimeReminder(bool value) async {
    isBedtimeReminderEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bedtimeReminderKey, value);
    BedtimeReminderService().scheduleBedtimeReminder();
  }

  /// Set sleep duration
  Future<void> setSleepDuration(int hours) async {
    sleepDurationHours.value = hours;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sleepDurationKey, hours);
    BedtimeReminderService().scheduleBedtimeReminder();
  }

  /// Get translated string
  String tr(String key) {
    return translations[key] ?? key;
  }

  /// Check if current language is Arabic
  bool get isArabic => locale.value == 'ar';

  /// Check if sound mode includes adhan
  bool get hasAdhan => soundMode.value == 'adhan_vibrate';

  /// Check if sound mode includes vibration
  bool get hasVibration => soundMode.value != 'silent';
}

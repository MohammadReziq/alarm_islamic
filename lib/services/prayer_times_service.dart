import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/prayer_times_model.dart';
import 'location_service.dart';

/// Prayer times service - Offline-first with monthly caching
class PrayerTimesService {
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;
  PrayerTimesService._internal();

  static const String boxName = 'prayer_times';
  static const String _lastUpdateKey = 'prayer_times_last_update';

  /// Get prayer times for today (offline)
  Future<PrayerTimesModel?> getTodayPrayerTimes() async {
    try {
      final box = await Hive.openBox<PrayerTimesModel>(boxName);
      final today = _getDateKey(DateTime.now());

      return box.get(today);
    } catch (e) {
      print('Error getting today prayer times: $e');
      return null;
    }
  }

  /// Fetch and save monthly prayer times from API
  Future<bool> fetchAndSaveMonthlyPrayerTimes() async {
    try {
      // Get location
      final locationService = LocationService();
      Position? position = await locationService.getCurrentLocation();

      if (position == null) {
        // Try saved location
        position = await locationService.getSavedLocation();
        if (position == null) {
          print('❌ No location available');
          return false;
        }
      }

      // Fetch from Aladhan API (monthly calendar)
      final now = DateTime.now();
      final url =
          'https://api.aladhan.com/v1/calendar/'
          '${now.year}/${now.month}'
          '?latitude=${position.latitude}'
          '&longitude=${position.longitude}'
          '&method=4'; // Umm Al-Qura calculation method

      print('🌐 Fetching prayer times from API...');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 200) {
          final monthData = data['data'] as List;

          // Save to Hive
          final box = await Hive.openBox<PrayerTimesModel>(boxName);

          for (var dayData in monthData) {
            final prayerTime = PrayerTimesModel.fromJson(dayData);
            final dateKey = _convertDateKey(prayerTime.date);
            await box.put(dateKey, prayerTime);
          }

          // Update last fetch date
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            _lastUpdateKey,
            DateTime.now().toIso8601String(),
          );

          print('✅ Saved ${monthData.length} days of prayer times');
          return true;
        }
      }

      print('❌ API request failed: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Error fetching prayer times: $e');
      return false;
    }
  }

  /// Check if we need to update (monthly)
  Future<bool> needsUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);

      if (lastUpdateStr == null) return true;

      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();

      // Update if more than 30 days or if it's a new month
      return now.difference(lastUpdate).inDays > 30 ||
          now.month != lastUpdate.month;
    } catch (e) {
      return true;
    }
  }

  /// Update if needed (background task)
  Future<void> updateIfNeeded() async {
    if (await needsUpdate()) {
      await fetchAndSaveMonthlyPrayerTimes();
    }
  }

  /// Get date key for Hive storage
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Convert DD-MM-YYYY to YYYY-MM-DD
  String _convertDateKey(String ddmmyyyy) {
    final parts = ddmmyyyy.split('-');
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  /// Check if prayer times are available offline
  Future<bool> hasPrayerTimes() async {
    final times = await getTodayPrayerTimes();
    return times != null;
  }

  /// Get first Adhan time (typically 20 minutes before Fajr)
  Future<DateTime?> getFirstAdhanTime() async {
    final today = await getTodayPrayerTimes();
    if (today == null) return null;
    
    return today.getFajrDateTime().subtract(const Duration(minutes: 20));
  }

  /// Get second Adhan time (the actual Fajr time)
  Future<DateTime?> getSecondAdhanTime() async {
    final today = await getTodayPrayerTimes();
    if (today == null) return null;
    
    return today.getFajrDateTime();
  }

  /// Get suggested Fajr alarm times with labels
  /// Returns a list of FajrAlarmSuggestion with different offset options
  Future<List<FajrAlarmSuggestion>> getSuggestedFajrAlarmTimes() async {
    final today = await getTodayPrayerTimes();
    if (today == null) return [];

    final fajrTime = today.getFajrDateTime();
    final firstAdhanTime = fajrTime.subtract(const Duration(minutes: 20));

    return [
      // First Adhan options
      FajrAlarmSuggestion(
        time: firstAdhanTime.subtract(const Duration(minutes: 15)),
        label: 'قبل الأذان الأول بـ 15 دقيقة',
        labelShort: 'قبل الأول -15د',
        isFirstAdhan: true,
        offsetMinutes: -15,
      ),
      FajrAlarmSuggestion(
        time: firstAdhanTime,
        label: 'مع الأذان الأول',
        labelShort: 'الأذان الأول',
        isFirstAdhan: true,
        offsetMinutes: 0,
      ),
      FajrAlarmSuggestion(
        time: firstAdhanTime.add(const Duration(minutes: 15)),
        label: 'بعد الأذان الأول بـ 15 دقيقة',
        labelShort: 'بعد الأول +15د',
        isFirstAdhan: true,
        offsetMinutes: 15,
      ),
      // Second Adhan options
      FajrAlarmSuggestion(
        time: fajrTime.subtract(const Duration(minutes: 15)),
        label: 'قبل أذان الفجر بـ 15 دقيقة',
        labelShort: 'قبل الفجر -15د',
        isFirstAdhan: false,
        offsetMinutes: -15,
      ),
      FajrAlarmSuggestion(
        time: fajrTime,
        label: 'مع أذان الفجر (الثاني)',
        labelShort: 'أذان الفجر',
        isFirstAdhan: false,
        offsetMinutes: 0,
        isRecommended: true,
      ),
      FajrAlarmSuggestion(
        time: fajrTime.add(const Duration(minutes: 15)),
        label: 'بعد أذان الفجر بـ 15 دقيقة',
        labelShort: 'بعد الفجر +15د',
        isFirstAdhan: false,
        offsetMinutes: 15,
      ),
    ];
  }

  /// Get formatted time string
  String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'ص' : 'م';
    final displayHour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    return '$displayHour:$minute $period';
  }
}

/// Model for Fajr alarm suggestion
class FajrAlarmSuggestion {
  final DateTime time;
  final String label;
  final String labelShort;
  final bool isFirstAdhan;
  final int offsetMinutes;
  final bool isRecommended;

  FajrAlarmSuggestion({
    required this.time,
    required this.label,
    required this.labelShort,
    required this.isFirstAdhan,
    required this.offsetMinutes,
    this.isRecommended = false,
  });

  /// Get formatted time string
  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'ص' : 'م';
    final displayHour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    return '$displayHour:$minute $period';
  }

  /// Get alarm label for saving
  String get alarmLabel {
    final type = isFirstAdhan ? 'الأذان الأول' : 'أذان الفجر';
    String offsetStr = '';
    if (offsetMinutes > 0) offsetStr = ' (+${offsetMinutes}د)';
    if (offsetMinutes < 0) offsetStr = ' (${offsetMinutes}د)';
    return 'صلاة الفجر - $type$offsetStr';
  }
}

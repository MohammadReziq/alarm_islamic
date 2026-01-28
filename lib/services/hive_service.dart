import 'package:hive_flutter/hive_flutter.dart';
import '../models/alarm_model.dart';
import '../models/stats_model.dart';
import '../models/prayer_times_model.dart';

/// Hive local storage service
class HiveService {
  static const String _alarmsBox = 'alarms';
  static const String _statsBox = 'stats';
  static const String _prayerTimesBox = 'prayer_times';
  static const String _statsKey = 'user_stats';

  /// Initialize Hive and register adapters
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register type adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AlarmModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StatsModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PrayerTimesModelAdapter());
    }

    // Open boxes
    await Hive.openBox<AlarmModel>(_alarmsBox);
    await Hive.openBox<StatsModel>(_statsBox);
    // Prayer times box will be opened when needed
  }

  // ========== ALARMS ==========

  /// Get alarms box
  static Box<AlarmModel> get _alarmsBoxInstance {
    return Hive.box<AlarmModel>(_alarmsBox);
  }

  /// Get all alarms
  static List<AlarmModel> getAllAlarms() {
    return _alarmsBoxInstance.values.toList();
  }

  /// Get alarm by ID
  static AlarmModel? getAlarm(String id) {
    return _alarmsBoxInstance.get(id);
  }

  /// Save alarm
  static Future<void> saveAlarm(AlarmModel alarm) async {
    await _alarmsBoxInstance.put(alarm.id, alarm);
  }

  /// Delete alarm
  static Future<void> deleteAlarm(String id) async {
    await _alarmsBoxInstance.delete(id);
  }

  /// Update alarm
  static Future<void> updateAlarm(AlarmModel alarm) async {
    await _alarmsBoxInstance.put(alarm.id, alarm);
  }

  /// Clear all alarms (for testing)
  static Future<void> clearAlarms() async {
    await _alarmsBoxInstance.clear();
  }

  // ========== STATS ==========

  /// Get stats box
  static Box<StatsModel> get _statsBoxInstance {
    return Hive.box<StatsModel>(_statsBox);
  }

  /// Get user stats
  static StatsModel getStats() {
    final stats = _statsBoxInstance.get(_statsKey);
    return stats ?? StatsModel();
  }

  /// Save stats
  static Future<void> saveStats(StatsModel stats) async {
    await _statsBoxInstance.put(_statsKey, stats);
  }

  /// Clear stats (for testing)
  static Future<void> clearStats() async {
    await _statsBoxInstance.clear();
  }

  /// Close all boxes (cleanup)
  static Future<void> close() async {
    await Hive.close();
  }
}

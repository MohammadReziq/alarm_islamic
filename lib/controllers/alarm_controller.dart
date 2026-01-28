import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/alarm_model.dart';
import '../services/hive_service.dart';
import '../services/alarm_service.dart';
import '../services/bedtime_reminder_service.dart';

/// Alarm controller for managing alarms with GetX
class AlarmController extends GetxController {
  final _alarmService = AlarmService();
  
  // Observable alarm list
  final RxList<AlarmModel> alarms = <AlarmModel>[].obs;

  // Sort order
  final RxBool sortByTime = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadAlarms();
  }

  /// Load all alarms from Hive
  void loadAlarms() {
    final loadedAlarms = HiveService.getAllAlarms();
    alarms.value = loadedAlarms;
    _sortAlarms();
    
    // Schedule bedtime reminder on app start
    BedtimeReminderService().scheduleBedtimeReminder();
  }

  /// Add new alarm
  Future<void> addAlarm({
    required int hour,
    required int minute,
    required String label,
    required List<int> repeatDays,
    String soundPath = 'assets/sounds/alarms_sound/makkah.mp3',
    String vibrationPattern = 'continuous',
  }) async {
    final alarm = AlarmModel(
      id: const Uuid().v4(),
      hour: hour,
      minute: minute,
      label: label,
      isEnabled: true,
      repeatDays: repeatDays,
      soundPath: soundPath,
      createdAt: DateTime.now(),
      vibrationPattern: vibrationPattern,
    );

    // Save to Hive
    await HiveService.saveAlarm(alarm);

    // Schedule alarm
    await _alarmService.scheduleAlarm(alarm);

    // Update list
    alarms.add(alarm);
    _sortAlarms();

    // Schedule bedtime reminder
    BedtimeReminderService().scheduleBedtimeReminder();

    Get.snackbar(
      'تم',
      'تم إضافة المنبه بنجاح',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Update existing alarm
  Future<void> updateAlarm(AlarmModel updatedAlarm) async {
    // Save to Hive
    await HiveService.updateAlarm(updatedAlarm);

    // Cancel old alarm
    await _alarmService.cancelAlarm(updatedAlarm.id);

    // Reschedule if enabled
    if (updatedAlarm.isEnabled) {
      await _alarmService.scheduleAlarm(updatedAlarm);
    }

    // Update list
    final index = alarms.indexWhere((a) => a.id == updatedAlarm.id);
    if (index != -1) {
      alarms[index] = updatedAlarm;
      _sortAlarms();
    }

    // Schedule bedtime reminder
    BedtimeReminderService().scheduleBedtimeReminder();

    Get.snackbar(
      'تم',
      'تم تحديث المنبه بنجاح',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Delete alarm
  Future<void> deleteAlarm(String alarmId) async {
    // Cancel alarm
    await _alarmService.cancelAlarm(alarmId);

    // Delete from Hive
    await HiveService.deleteAlarm(alarmId);

    // Remove from list
    alarms.removeWhere((a) => a.id == alarmId);

    // Schedule bedtime reminder
    BedtimeReminderService().scheduleBedtimeReminder();

    Get.snackbar(
      'تم',
      'تم حذف المنبه',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Toggle alarm on/off
  Future<void> toggleAlarm(String alarmId) async {
    final alarm = alarms.firstWhere((a) => a.id == alarmId);
    final updatedAlarm = alarm.copyWith(isEnabled: !alarm.isEnabled);

    await updateAlarm(updatedAlarm);
    
    // Schedule bedtime reminder
    BedtimeReminderService().scheduleBedtimeReminder();
  }

  /// Snooze alarm (increment snooze count and reschedule)
  Future<void> snoozeAlarm(String alarmId) async {
    final alarm = alarms.firstWhere((a) => a.id == alarmId);
    
    if (!alarm.canSnooze) {
      Get.snackbar(
        'تحذير',
        'لقد استخدمت كل محاولات الغفوة',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final updatedAlarm = alarm.incrementSnooze();
    await HiveService.updateAlarm(updatedAlarm);

    // Schedule snooze
    await _alarmService.snoozeAlarm(updatedAlarm);

    // Update list
    final index = alarms.indexWhere((a) => a.id == alarmId);
    if (index != -1) {
      alarms[index] = updatedAlarm;
    }

    final duration = updatedAlarm.snoozeDuration;
    Get.snackbar(
      'غفوة',
      'سيرن المنبه بعد $duration دقيقة',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Reset snooze count for an alarm
  Future<void> resetSnooze(String alarmId) async {
    final alarm = alarms.firstWhere((a) => a.id == alarmId);
    final updatedAlarm = alarm.resetSnooze();
    
    await HiveService.updateAlarm(updatedAlarm);

    final index = alarms.indexWhere((a) => a.id == alarmId);
    if (index != -1) {
      alarms[index] = updatedAlarm;
    }
  }

  /// Get next alarm (closest enabled alarm)
  AlarmModel? get nextAlarm {
    final enabled = alarms.where((a) => a.isEnabled).toList();
    if (enabled.isEmpty) return null;

    // Find closest alarm
    final now = DateTime.now();
    AlarmModel? closest;
    Duration? closestDuration;

    for (final alarm in enabled) {
      DateTime alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.hour,
        alarm.minute,
      );

      // If time has passed today, check tomorrow
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      final duration = alarmTime.difference(now);
      if (closestDuration == null || duration < closestDuration) {
        closestDuration = duration;
        closest = alarm;
      }
    }

    return closest;
  }

  /// Get time until next alarm
  Duration? get timeUntilNextAlarm {
    final next = nextAlarm;
    if (next == null) return null;

    final now = DateTime.now();
    DateTime alarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      next.hour,
      next.minute,
    );

    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    return alarmTime.difference(now);
  }

  /// Sort alarms
  void _sortAlarms() {
    if (sortByTime.value) {
      alarms.sort((a, b) {
        final timeA = a.hour * 60 + a.minute;
        final timeB = b.hour * 60 + b.minute;
        return timeA.compareTo(timeB);
      });
    } else {
      alarms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  /// Toggle sort order
  void toggleSortOrder() {
    sortByTime.value = !sortByTime.value;
    _sortAlarms();
  }
}

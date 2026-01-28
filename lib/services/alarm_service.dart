import 'package:alarm/alarm.dart' as alarm_pkg;
import 'package:alarm_islamic/controllers/alarm_controller.dart';
import 'package:get/get.dart';
import '../models/alarm_model.dart';
import '../screens/alarm_ring_screen.dart';

/// Alarm scheduling service using alarm package
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  /// Initialize alarm service
  Future<void> init() async {
    await alarm_pkg.Alarm.init();

    // Listen for alarm ring events
    alarm_pkg.Alarm.ringStream.stream.listen((alarmSettings) {
      _onAlarmRing(alarmSettings);
    });

    print('✅ Alarm service initialized');
  }

  /// Schedule an alarm
  Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) return;

    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // For repeating alarms, find the next occurrence
    if (alarm.hasRepeat) {
      scheduledTime = _getNextOccurrence(alarm, now);
    }

    final alarmSettings = alarm_pkg.AlarmSettings(
      id: alarm.id.hashCode,
      dateTime: scheduledTime,
      assetAudioPath: alarm.soundPath,
      loopAudio: true,
      // Only use native vibration for continuous pattern
      // For custom patterns (pulse, wave, etc.), we handle it in AlarmRingScreen
      vibrate: alarm.vibrationPattern == 'continuous',
      volumeSettings: alarm_pkg.VolumeSettings.fade(
        fadeDuration: const Duration(seconds: 10),
      ),
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      notificationSettings: alarm_pkg.NotificationSettings(
        title: 'منبه النشور',
        body: alarm.label.isNotEmpty
            ? alarm.label
            : 'انطق دعاء الاستيقاظ لإيقاف المنبه',
        icon: 'notification_icon',
      ),
    );

    await alarm_pkg.Alarm.set(alarmSettings: alarmSettings);

    print('✅ Alarm scheduled: ${alarm.formattedTime} at $scheduledTime');
  }

  /// Cancel an alarm
  Future<void> cancelAlarm(String alarmId) async {
    await alarm_pkg.Alarm.stop(alarmId.hashCode);
    print('❌ Alarm cancelled: $alarmId');
  }

  /// Reschedule all enabled alarms (after reboot)
  Future<void> rescheduleAllAlarms(List<AlarmModel> alarms) async {
    for (final alarm in alarms) {
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
    }
    print('🔄 Rescheduled ${alarms.length} alarms');
  }

  /// Get next occurrence for repeating alarm
  DateTime _getNextOccurrence(AlarmModel alarm, DateTime now) {
    DateTime next = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.hour,
      alarm.minute,
    );

    // If time has passed today, start from tomorrow
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    // Find next matching weekday
    for (int i = 0; i < 8; i++) {
      final weekday = next.weekday == 7
          ? 0
          : next.weekday; // Convert to our format
      if (alarm.shouldRingOn(weekday)) {
        return next;
      }
      next = next.add(const Duration(days: 1));
    }

    return next; // Fallback (should never reach here)
  }

  /// Snooze an alarm (reschedule for X minutes later)
  Future<void> snoozeAlarm(AlarmModel alarm) async {
    if (!alarm.canSnooze) return;

    final snoozeDuration = alarm.snoozeDuration;
    final snoozeTime = DateTime.now().add(Duration(minutes: snoozeDuration));

    final alarmSettings = alarm_pkg.AlarmSettings(
      id: alarm.id.hashCode,
      dateTime: snoozeTime,
      assetAudioPath: alarm.soundPath,
      loopAudio: true,
      volumeSettings: alarm_pkg.VolumeSettings.fade(
        fadeDuration: const Duration(seconds: 10),
      ),
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      notificationSettings: alarm_pkg.NotificationSettings(
        title: 'منبه النشور (غفوة)',
        body: 'انطق دعاء الاستيقاظ لإيقاف المنبه',
        icon: 'notification_icon',
      ),
    );

    await alarm_pkg.Alarm.set(alarmSettings: alarmSettings);

    print('💤 Alarm snoozed for $snoozeDuration minutes');
  }

  /// Called when alarm rings - navigate to AlarmRingScreen
  /// Called when alarm rings - navigate to AlarmRingScreen
  void _onAlarmRing(alarm_pkg.AlarmSettings alarmSettings) async {
    print('🔔 Alarm ringing! ID: ${alarmSettings.id}');

    try {
      // Ensure controller exists
      if (!Get.isRegistered<AlarmController>()) {
        Get.put(AlarmController());
      }
      
      final alarmController = Get.find<AlarmController>();
      final alarms = alarmController.alarms;

      final alarm = alarms.firstWhere(
        (a) => a.id.hashCode == alarmSettings.id,
        orElse: () {
          // If alarm not found, create a temporary one
          return AlarmModel(
            id: alarmSettings.id.toString(),
            hour: alarmSettings.dateTime.hour,
            minute: alarmSettings.dateTime.minute,
            isEnabled: true,
            soundPath: alarmSettings.assetAudioPath,
            label: alarmSettings.notificationSettings.body,
            repeatDays: [],
            createdAt: DateTime.now(),
          );
        },
      );

      // Safe Navigation with Retry
      // Wait for Get.context to be available (app might be starting up)
      int retries = 0;
      while (Get.context == null && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
        print('⏳ Waiting for app context... ($retries)');
      }

      if (Get.context != null) {
        Get.to(
          () => AlarmRingScreen(alarm: alarm),
          preventDuplicates: true,
          routeName: '/alarm_ring',
        );
        print('✅ Navigated to AlarmRingScreen');
      } else {
        print('❌ Failed to navigate: Context is null after retries');
        // Fallback: Launch app via intent if possible or show notification
      }

    } catch (e) {
      print('❌ Error navigating to AlarmRingScreen: $e');
    }
  }

  /// Check if an alarm is currently ringing
  static Future<bool> isRinging(String alarmId) async {
    return await alarm_pkg.Alarm.hasAlarm();
  }

  /// Stop a ringing alarm
  Future<void> stopAlarm(String alarmId) async {
    await alarm_pkg.Alarm.stop(alarmId.hashCode);
  }
}

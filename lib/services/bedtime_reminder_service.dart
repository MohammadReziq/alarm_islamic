import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/alarm_controller.dart';
import '../controllers/settings_controller.dart';
import 'notification_service.dart';
import '../models/alarm_model.dart';

class BedtimeReminderService {
  static final BedtimeReminderService _instance = BedtimeReminderService._internal();
  factory BedtimeReminderService() => _instance;
  BedtimeReminderService._internal();

  /// Schedule bedtime reminder based on next alarm
  Future<void> scheduleBedtimeReminder() async {
    try {
      if (!Get.isRegistered<SettingsController>() || !Get.isRegistered<AlarmController>()) {
        return;
      }

      final settingsController = Get.find<SettingsController>();
      final alarmController = Get.find<AlarmController>();

      // Check if enabled
      if (!settingsController.isBedtimeReminderEnabled.value) {
        await NotificationService().cancelNotificationById(888); // 888 is reserved for bedtime
        print('💤 Bedtime reminder disabled');
        return;
      }

      // Get next alarm
      final nextAlarm = alarmController.nextAlarm;
      if (nextAlarm == null) {
        await NotificationService().cancelNotificationById(888);
        return;
      }

      // Calculate bedtime
      final sleepDuration = Duration(hours: settingsController.sleepDurationHours.value);
      final now = DateTime.now();
      
      DateTime alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        nextAlarm.hour,
        nextAlarm.minute,
      );

      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      final bedtime = alarmTime.subtract(sleepDuration);

      // If bedtime is in the past (e.g., alarm is in 2 hours but we need 7 hours sleep), 
      // check if it's relevant to notify immediately or skip
      // For now, only schedule if bedtime is in the future
      if (bedtime.isAfter(now)) {
        print('💤 Scheduling bedtime reminder at $bedtime for alarm at $alarmTime');
        
        await NotificationService().scheduleNotification(
          id: 888,
          title: '🌙 حان وقت النوم!',
          body: 'منبه القادم: ${nextAlarm.formattedTimeArabic} (بعد ${settingsController.sleepDurationHours.value} ساعات)\nلتحصل على نوم صحي، نم الآن ✨',
          payload: 'bedtime_reminder',
          scheduledDate: bedtime,
        );
      }
    } catch (e) {
      print('❌ Error scheduling bedtime reminder: $e');
    }
  }
}

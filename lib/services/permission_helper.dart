import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:android_intent_plus/android_intent.dart';

/// Permission Helper - Request exact alarm and other permissions
class PermissionHelper {
  /// Request exact alarm permission (Android 12+)
  static Future<bool> requestExactAlarmPermission() async {
    // Check if permission is already granted
    final status = await Permission.scheduleExactAlarm.status;
    
    if (status.isGranted) {
      return true;
    }

    // Request permission
    final result = await Permission.scheduleExactAlarm.request();
    
    if (!result.isGranted) {
      // Take user to settings if denied
      await _showExactAlarmDialog();
    }
    
    return result.isGranted;
  }

  /// Request notification permission (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.microphone.request();
    
    if (!result.isGranted) {
      await _showMicrophoneDialog();
    }
    
    return result.isGranted;
  }

  /// Show dialog and take user to exact alarm settings
  static Future<void> _showExactAlarmDialog() async {
    final shouldOpen = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('صلاحية المنبهات الدقيقة'),
        content: const Text(
          'يحتاج التطبيق إلى صلاحية "المنبهات الدقيقة" لضمان رنين المنبه في الوقت المحدد.\n\nسنأخذك إلى الإعدادات للسماح بذلك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      await openExactAlarmSettings();
    }
  }

  /// Show dialog for microphone permission
  static Future<void> _showMicrophoneDialog() async {
    Get.dialog(
      AlertDialog(
        title: const Text('صلاحية الميكروفون'),
        content: const Text(
          'يحتاج التطبيق إلى الميكروفون للتعرف على صوتك عند نطق دعاء الاستيقاظ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('حسناً'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  /// Open exact alarm settings page
  static Future<void> openExactAlarmSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        package: 'com.example.alarm_islamic',
      );
      await intent.launch();
    } catch (e) {
      // Fallback to general settings
      await openAppSettings();
    }
  }

  /// Request all required permissions at once
  static Future<void> requestAllPermissions() async {
    await requestNotificationPermission();
    await requestMicrophonePermission();
    await requestExactAlarmPermission();
  }
}

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

/// Manages all app permissions with smart request flow
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // ========================
  // Location Permission
  // ========================

  /// Check location permission status
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      await _showPermissionDialog(
        title: 'إذن الموقع مطلوب',
        message: 'نحتاج موقعك لتحديد أوقات الصلاة بدقة حسب منطقتك',
        onOpenSettings: () => openAppSettings(),
      );
    }

    return status.isGranted;
  }

  // ========================
  // Exact Alarm Permission (Android 12+)
  // ========================

  /// Check exact alarm permission
  Future<bool> hasExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  /// Request exact alarm permission (critical for alarms)
  Future<bool> requestExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.request();

    if (!status.isGranted) {
      await _showPermissionDialog(
        title: 'صلاحية المنبهات الدقيقة',
        message:
            'يحتاج التطبيق لصلاحية "المنبهات الدقيقة" لضمان رنين المنبه في الوقت المحدد بالضبط.\n\nسنأخذك للإعدادات للسماح بذلك.',
        onOpenSettings: () => _openExactAlarmSettings(),
      );
    }

    return status.isGranted;
  }

  /// Open exact alarm settings page
  Future<void> _openExactAlarmSettings() async {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        package: 'com.example.alarm_islamic',
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Error opening exact alarm settings: $e');
      await openAppSettings();
    }
  }

  // ========================
  // Notification Permission (Android 13+)
  // ========================

  /// Check notification permission
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();

    if (status.isDenied) {
      await _showPermissionDialog(
        title: 'إذن الإشعارات',
        message:
            'نحتاج إذن الإشعارات لإرسال تنبيهات المنبه وفتح الشاشة عند الرنين',
        onOpenSettings: () => openAppSettings(),
      );
    }

    return status.isGranted;
  }

  // ========================
  // Microphone Permission
  // ========================

  /// Check microphone permission
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      await _showPermissionDialog(
        title: 'إذن الميكروفون',
        message: 'نحتاج الميكروفون للتعرف على دعاء الاستيقاظ عند إيقاف المنبه',
        onOpenSettings: () => openAppSettings(),
      );
    }

    return status.isGranted;
  }

  // ========================
  // Request All Critical Permissions
  // ========================

  /// Request all permissions needed for alarm functionality
  Future<void> requestAlarmPermissions() async {
    // Order matters - most critical first
    await requestNotificationPermission();
    await requestExactAlarmPermission();
  }

  /// Request all permissions at app launch
  Future<void> requestAllPermissions() async {
    await requestNotificationPermission();
    await requestMicrophonePermission();
    await requestExactAlarmPermission();
  }

  // ========================
  // DND & Battery Optimization
  // ========================

  /// Check DND/Notification Policy Access
  Future<bool> hasDNDAccess() async {
    return await Permission.accessNotificationPolicy.isGranted;
  }

  /// Request DND Access to bypass Do Not Disturb
  Future<bool> requestDNDAccess() async {
    final status = await Permission.accessNotificationPolicy.request();
    
    if (!status.isGranted) {
       await _showPermissionDialog(
          title: 'تجاوز "عدم الإزعاج"',
          message: 'لضمان رنين منبه الفجر حتى في وضع "عدم الإزعاج" أو "الصامت"، يرجى منح هذا الإذن.',
          onOpenSettings: () => openAppSettings(),
       );
    }
    return status.isGranted;
  }

  // ========================
  // Helper: Permission Dialog
  // ========================

  Future<void> _showPermissionDialog({
    required String title,
    required String message,
    required VoidCallback onOpenSettings,
  }) async {
    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              onOpenSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
}

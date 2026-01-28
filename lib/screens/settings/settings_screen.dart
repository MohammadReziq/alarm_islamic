import 'package:alarm_islamic/controllers/settings_controller.dart';
import 'package:alarm_islamic/controllers/theme_controller.dart';
import 'package:alarm_islamic/core/app_theme.dart';
import 'package:alarm_islamic/services/prayer_times_service.dart';
import 'package:alarm_islamic/services/permission_service.dart';
import 'package:alarm_islamic/services/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Settings Screen - Configure language, theme, and sound
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: Obx(() => Text(settingsController.tr('settings')))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Section
          _buildSectionTitle(context, settingsController.tr('language')),
          Obx(
            () => ListTile(
              leading: const Icon(Icons.language),
              title: Text(settingsController.tr('language')),
              trailing: DropdownButton<String>(
                value: settingsController.locale.value,
                items: [
                  DropdownMenuItem(
                    value: 'ar',
                    child: Text(settingsController.tr('arabic')),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(settingsController.tr('english')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settingsController.changeLanguage(value);
                  }
                },
              ),
            ),
          ),

          const Divider(height: 32),

          // Theme Section
          _buildSectionTitle(context, settingsController.tr('theme')),
          Obx(
            () => SwitchListTile(
              secondary: Icon(
                themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              title: Text(settingsController.tr('dark_mode')),
              value: themeController.isDarkMode,
              onChanged: (value) => themeController.toggleTheme(),
            ),
          ),

          const Divider(height: 32),

          // Permissions Section
          _buildSectionTitle(context, 'الأذونات'),
          _buildPermissionTile(
            context,
            icon: Icons.mic,
            title: 'الميكروفون',
            subtitle: 'مطلوب لقول الدعاء وإيقاف المنبه',
            permissionCheck: () =>
                PermissionService().hasMicrophonePermission(),
            onRequest: () => PermissionService().requestMicrophonePermission(),
          ),
          _buildPermissionTile(
            context,
            icon: Icons.location_on,
            title: 'الموقع',
            subtitle: 'مطلوب لتحديد مواقيت الصلاة',
            permissionCheck: () => PermissionService().hasLocationPermission(),
            onRequest: () => PermissionService().requestLocationPermission(),
          ),
          _buildPermissionTile(
            context,
            icon: Icons.notifications,
            title: 'الإشعارات',
            subtitle: 'مطلوب لتنبيهات المنبه',
            permissionCheck: () =>
                PermissionService().hasNotificationPermission(),
            onRequest: () =>
                PermissionService().requestNotificationPermission(),
          ),
          _buildPermissionTile(
            context,
            icon: Icons.alarm,
            title: 'المنبهات الدقيقة',
            subtitle: 'مطلوب لرنين المنبه في الوقت المحدد',
            permissionCheck: () =>
                PermissionService().hasExactAlarmPermission(),
            onRequest: () => PermissionService().requestExactAlarmPermission(),
          ),
          _buildPermissionTile(
            context,
            icon: Icons.do_not_disturb,
            title: 'تجاوز "عدم الإزعاج"',
            subtitle: 'مطلوب لرنين المنبه في الوضع الصامت',
            permissionCheck: () => PermissionService().hasDNDAccess(),
            onRequest: () => PermissionService().requestDNDAccess(),
          ),

          const Divider(height: 32),

          // Prayer Times Section (Optional Feature)
          _buildSectionTitle(context, 'مواقيت الصلاة (اختياري)'),
          FutureBuilder<bool>(
            future: _checkPrayerTimesStatus(),
            builder: (context, snapshot) {
              final isEnabled = snapshot.data ?? false;

              return ListTile(
                leading: Icon(
                  isEnabled ? Icons.location_on : Icons.location_off,
                  color: isEnabled ? AppTheme.gold : null,
                ),
                title: const Text('تفعيل مواقيت الصلاة'),
                subtitle: Text(
                  isEnabled
                      ? 'مفعّل ✅ - يمكنك الآن إضافة منبه الفجر الذكي'
                      : 'معطّل - فعّله لميزة منبه الفجر التلقائي',
                  style: TextStyle(
                    fontSize: 12,
                    color: isEnabled
                        ? AppTheme.success
                        : AppTheme.textSecondary,
                  ),
                ),
                trailing: ElevatedButton(
                  onPressed: () => _enablePrayerTimes(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnabled
                        ? AppTheme.cardBg
                        : AppTheme.gold,
                    foregroundColor: isEnabled
                        ? AppTheme.gold
                        : AppTheme.midnight,
                  ),
                  child: Text(isEnabled ? 'تحديث' : 'تفعيل'),
                ),
              );
            },
          ),

          const Divider(height: 32),

          // Sound Settings Section
          _buildSectionTitle(context, settingsController.tr('sound_settings')),
          Obx(
            () => RadioListTile<String>(
              secondary: const Icon(Icons.volume_up),
              title: Text(settingsController.tr('adhan_vibrate')),
              subtitle: const Text('🔊 + 📳'),
              value: 'adhan_vibrate',
              groupValue: settingsController.soundMode.value,
              onChanged: (value) {
                if (value != null) {
                  settingsController.changeSoundMode(value);
                }
              },
            ),
          ),
          Obx(
            () => RadioListTile<String>(
              secondary: const Icon(Icons.vibration),
              title: Text(settingsController.tr('vibrate_only')),
              subtitle: const Text('📳'),
              value: 'vibrate_only',
              groupValue: settingsController.soundMode.value,
              onChanged: (value) {
                if (value != null) {
                  settingsController.changeSoundMode(value);
                }
              },
            ),
          ),
          Obx(
            () => RadioListTile<String>(
              secondary: const Icon(Icons.volume_off),
              title: Text(settingsController.tr('silent')),
              subtitle: const Text('🔇'),
              value: 'silent',
              groupValue: settingsController.soundMode.value,
              onChanged: (value) {
                if (value != null) {
                  settingsController.changeSoundMode(value);
                }
              },
            ),
          ),
          
          const Divider(height: 32),
          
          // Bedtime Reminder Section
          _buildSectionTitle(context, 'تذكير وقت النوم'),
          Obx(() => SwitchListTile(
            title: const Text('تفعيل التذكير'),
            subtitle: Text('قبل ${settingsController.sleepDurationHours.value} ساعات من أدنى وقت للفجر'),
            value: settingsController.isBedtimeReminderEnabled.value,
            onChanged: (val) => settingsController.toggleBedtimeReminder(val),
          )),
          Obx(() => ListTile(
            title: const Text('مدة النوم المستهدفة'),
            subtitle: Text('${settingsController.sleepDurationHours.value} ساعات'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    if (settingsController.sleepDurationHours.value > 4) {
                      settingsController.setSleepDuration(settingsController.sleepDurationHours.value - 1);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    if (settingsController.sleepDurationHours.value < 12) {
                      settingsController.setSleepDuration(settingsController.sleepDurationHours.value + 1);
                    }
                  },
                ),
              ],
            ),
          )),

          const Divider(height: 32),

          // Backup Section
          _buildSectionTitle(context, settingsController.tr('backup')),
          Text(
            settingsController.tr('backup_desc'),
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ).paddingOnly(bottom: 8),
          ListTile(
            leading: const Icon(Icons.share, color: AppTheme.gold),
            title: Text(settingsController.tr('export_file')),
            subtitle: const Text('Export data to a .json file and share it'),
            onTap: () async {
              try {
                await BackupService().shareDataAsFile();
                Get.snackbar('تم', 'تم تجهيز ملف النسخ الاحتياطي بنجاح ✅', backgroundColor: AppTheme.success, colorText: Colors.white);
              } catch (e) {
                Get.snackbar('خطأ', 'فشل تصدير الملف: $e', backgroundColor: AppTheme.error, colorText: Colors.white);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_open, color: AppTheme.gold),
            title: Text(settingsController.tr('import_file')),
            subtitle: const Text('Select a .json file to restore data'),
            onTap: () {
              Get.defaultDialog(
                title: settingsController.tr('warning') ?? 'تحذير',
                content: const Text('سيتم استبدال جميع المنبهات والإحصائيات الحالية. هل أنت متأكد؟'),
                textConfirm: settingsController.tr('confirm') ?? 'نعم، استعادة',
                textCancel: settingsController.tr('cancel'),
                confirmTextColor: Colors.white,
                buttonColor: AppTheme.error,
                onConfirm: () async {
                  Get.back();
                  try {
                    await BackupService().importDataFromFile();
                    Get.snackbar('تم', 'تم استعادة البيانات بنجاح ✅', backgroundColor: AppTheme.success, colorText: Colors.white);
                  } catch (e) {
                    Get.snackbar('خطأ', 'فشل الاستعادة من الملف: $e', backgroundColor: AppTheme.error, colorText: Colors.white);
                  }
                }
              );
            },
          ),
          const Divider(height: 16, color: Colors.transparent),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('نسخ كفص كود (Clipboard)'),
            onTap: () async {
              await BackupService().copyBackupToClipboard();
              Get.snackbar('تم', 'تم نسخ البيانات إلى الحافظة بنجاح ✅', backgroundColor: AppTheme.success, colorText: Colors.white);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.gold,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Future<bool> Function() permissionCheck,
    required Future<void> Function() onRequest,
  }) {
    return _PermissionTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      permissionCheck: permissionCheck,
      onRequest: onRequest,
    );
  }

  /// Check if prayer times are enabled
  Future<bool> _checkPrayerTimesStatus() async {
    try {
      final prayerService = PrayerTimesService();
      return await prayerService.hasPrayerTimes();
    } catch (e) {
      return false;
    }
  }

  /// Enable prayer times feature
  Future<void> _enablePrayerTimes(BuildContext context) async {
    // Show loading
    Get.dialog(
      Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                ),
                const SizedBox(height: 16),
                Text('جاري تفعيل مواقيت الصلاة...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // Request location
      final permissionService = PermissionService();
      final hasPermission = await permissionService.requestLocationPermission();

      if (!hasPermission) {
        Get.back();
        Get.snackbar(
          'خطأ',
          'نحتاج إذن الموقع لتفعيل هذه الميزة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.error,
          colorText: Colors.white,
        );
        return;
      }

      // Fetch prayer times
      final prayerService = PrayerTimesService();
      final success = await prayerService.fetchAndSaveMonthlyPrayerTimes();

      Get.back();

      if (success) {
        Get.snackbar(
          'نجح',
          'تم تفعيل مواقيت الصلاة بنجاح! ✅\nيمكنك الآن إضافة منبه الفجر الذكي',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'خطأ',
          'تعذر تحميل مواقيت الصلاة. تأكد من اتصالك بالإنترنت.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'خطأ',
        'حدث خطأ: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.error,
        colorText: Colors.white,
      );
    }
  }
}

class _PermissionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<bool> Function() permissionCheck;
  final Future<void> Function() onRequest;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.permissionCheck,
    required this.onRequest,
  });

  @override
  State<_PermissionTile> createState() => _PermissionTileState();
}

class _PermissionTileState extends State<_PermissionTile>
    with WidgetsBindingObserver {
  bool _isGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final status = await widget.permissionCheck();
    if (mounted) setState(() => _isGranted = status);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        widget.icon,
        color: _isGranted ? AppTheme.gold : AppTheme.textSecondary,
      ),
      title: Text(widget.title),
      subtitle: Text(
        widget.subtitle,
        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      trailing: _isGranted
          ? const Icon(Icons.check_circle, color: AppTheme.success)
          : ElevatedButton(
              onPressed: () async {
                await widget.onRequest();
                _checkStatus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.midnight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('تفعيل'),
            ),
    );
  }
}

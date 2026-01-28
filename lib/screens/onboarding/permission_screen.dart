import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/app_theme.dart';
import '../../services/permission_service.dart';
import '../alarm_list_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final _permService = PermissionService();

  bool _hasNotif = false;
  bool _hasMic = false;
  bool _hasExact = false;
  bool _hasDND = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notif = await _permService.hasNotificationPermission();
    final mic = await _permService.hasMicrophonePermission();
    final exact = await _permService.hasExactAlarmPermission();
    final dnd = await _permService.hasDNDAccess();

    if (mounted) {
      setState(() {
        _hasNotif = notif;
        _hasMic = mic;
        _hasExact = exact;
        _hasDND = dnd;
      });
    }

    if (notif && mic && exact) {
      // Small delay for UX
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Get.off(() => AlarmListScreen());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1026), Color(0xFF1A2347)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Text(
                  'الصلاحيات المطلوبة',
                  style: Get.textTheme.headlineLarge?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'يحتاج تطبيق نَشُور لبعض الصلاحيات لضمان عمل المنبه بشكل صحيح في كل الظروف.',
                  style: Get.textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                ),
                SizedBox(height: 40.h),
                Expanded(
                  child: ListView(
                    children: [
                      _buildPermissionTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'الإشعارات',
                        desc: 'لإظهار التنبيهات وفتح شاشة المنبه عند الرنين.',
                        isGranted: _hasNotif,
                        onTap: () async {
                          await _permService.requestNotificationPermission();
                          _checkPermissions();
                        },
                      ),
                      _buildPermissionTile(
                        icon: Icons.mic_none_outlined,
                        title: 'الميكروفون',
                        desc: 'للتعرف على صوتك عند نطق دعاء الاستيقاظ.',
                        isGranted: _hasMic,
                        onTap: () async {
                          await _permService.requestMicrophonePermission();
                          _checkPermissions();
                        },
                      ),
                      _buildPermissionTile(
                        icon: Icons.alarm_on_outlined,
                        title: 'المنبهات الدقيقة',
                        desc: 'لضمان رنين المنبه في الوقت المحدد بالضبط دون تأخير من النظام.',
                        isGranted: _hasExact,
                        onTap: () async {
                          await _permService.requestExactAlarmPermission();
                          _checkPermissions();
                        },
                      ),
                      _buildPermissionTile(
                        icon: Icons.do_not_disturb_on_outlined,
                        title: 'تجاوز عدم الإزعاج',
                        desc: 'ليعمل المنبه حتى لو كان الهاتف في وضع الصامت أو "عدم الإزعاج".',
                        isGranted: _hasDND,
                        onTap: () async {
                          await _permService.requestDNDAccess();
                          _checkPermissions();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    'يجب تفعيل أول 3 صلاحيات للمتابعة ⚠️',
                    style: Get.textTheme.bodySmall?.copyWith(color: AppTheme.error),
                  ),
                ),
                SizedBox(height: 8.h),
                ElevatedButton(
                  onPressed: (_hasNotif && _hasMic && _hasExact) 
                    ? () => Get.off(() => const AlarmListScreen()) 
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.midnight,
                    minimumSize: Size(double.infinity, 54.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: Text(
                    'بدء الاستخدام',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String desc,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isGranted ? AppTheme.success.withOpacity(0.5) : AppTheme.gold.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: isGranted ? AppTheme.success.withOpacity(0.1) : AppTheme.gold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isGranted ? AppTheme.success : AppTheme.gold,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  desc,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (isGranted)
            const Icon(Icons.check_circle, color: AppTheme.success)
          else
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.gold,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              child: const Text('تفعيل'),
            ),
        ],
      ),
    );
  }
}

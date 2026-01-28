import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/alarm_controller.dart';
import '../models/alarm_model.dart';
import '../widgets/gold_card.dart';
import '../widgets/digital_clock.dart';
import '../widgets/app_drawer.dart';
import '../core/app_theme.dart';
import '../services/prayer_times_service.dart';
import 'alarm_edit_screen.dart';
import 'dashboard_screen.dart';

/// Alarm List Screen - Main home screen (Samsung Clock layout)
class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alarmController = Get.put(AlarmController());

    return Scaffold(
      backgroundColor: AppTheme.midnight,
      appBar: AppBar(
        title: const Text('نَشُور'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () {
              Get.to(() => const DashboardScreen());
            },
            tooltip: 'الإحصائيات',
          ),
        ],
      ),
      drawer: const AppDrawer(), // Add drawer here
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1026), Color(0xFF1A2347)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Next alarm countdown section
            _buildNextAlarmHeader(alarmController),

            // NEXT FAJR INDICATOR
            FutureBuilder<String?>(
              future: _getNextFajrTime(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 8.h,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppTheme.gold.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wb_twilight,
                          color: AppTheme.gold,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'الفجر القادم: ${snapshot.data}',
                          style: Get.textTheme.titleMedium?.copyWith(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Alarm list
            Expanded(
              child: Obx(() {
                if (alarmController.alarms.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: alarmController.alarms.length,
                  itemBuilder: (context, index) {
                    final alarm = alarmController.alarms[index];
                    return _buildAlarmCard(context, alarm, alarmController);
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const AlarmEditScreen());
        },
        child: Icon(Icons.add, size: 28.sp),
      ),
    );
  }

  /// Next alarm countdown header
  Widget _buildNextAlarmHeader(AlarmController controller) {
    return Obx(() {
      final nextAlarm = controller.nextAlarm;
      final timeUntil = controller.timeUntilNextAlarm;

      if (nextAlarm == null || timeUntil == null) {
        return const SizedBox.shrink();
      }

      final hours = timeUntil.inHours;
      final minutes = timeUntil.inMinutes % 60;

      return GoldCard(
        padding: EdgeInsets.all(20.w),
        showBorder: true,
        child: Column(
          children: [
            Text(
              'التنبيه بعد ${hours > 0 ? "$hours ساعة و " : ""}$minutes دقيقة',
              style: Get.textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              nextAlarm.formattedTimeArabic,
              style: Get.textTheme.headlineLarge?.copyWith(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
                fontSize: 40.sp,
              ),
            ),
            if (nextAlarm.label.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(
                nextAlarm.label,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Build individual alarm card (Samsung Clock style)
  Widget _buildAlarmCard(
    BuildContext context,
    AlarmModel alarm,
    AlarmController controller,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GoldCard(
        onTap: () {
          Get.to(() => AlarmEditScreen(alarm: alarm));
        },
        child: Row(
          children: [
            // Toggle switch
            Obx(() {
              final currentAlarm = controller.alarms.firstWhere(
                (a) => a.id == alarm.id,
                orElse: () => alarm,
              );
              return Transform.scale(
                scale: 0.9.w,
                child: Switch(
                  value: currentAlarm.isEnabled,
                  onChanged: (value) {
                    controller.toggleAlarm(alarm.id);
                  },
                ),
              );
            }),

            SizedBox(width: 16.w),

            // Time and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time
                  Text(
                    alarm.formattedTimeArabic,
                    style: Get.textTheme.displaySmall?.copyWith(
                      color: alarm.isEnabled
                          ? AppTheme.gold
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 48.sp,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Label
                  if (alarm.label.isNotEmpty)
                    Text(
                      alarm.label,
                      style: Get.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 16.sp,
                      ),
                    ),

                  SizedBox(height: 8.h),

                  // Repeat days
                  Text(
                    alarm.repeatDaysArabic,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              icon: Icon(Icons.delete_outline, size: 24.sp),
              color: AppTheme.error,
              onPressed: () {
                _showDeleteDialog(context, alarm, controller);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_add,
            size: 80.sp,
            color: AppTheme.gold.withOpacity(0.3),
          ),
          SizedBox(height: 24.h),
          Text(
            'لا توجد منبهات',
            style: Get.textTheme.headlineMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 34.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'اضغط + لإضافة منبه جديد',
            style: Get.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary.withOpacity(0.7),
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteDialog(
    BuildContext context,
    AlarmModel alarm,
    AlarmController controller,
  ) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          'حذف المنبه؟',
          style: Get.textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف منبه ${alarm.formattedTimeArabic}؟',
          style: Get.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.deleteAlarm(alarm.id);
              Get.back();
            },
            child: const Text('حذف', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

/// Get next Fajr time formatted string
Future<String?> _getNextFajrTime() async {
  try {
    final prayerService = PrayerTimesService();
    if (!await prayerService.hasPrayerTimes()) return null;

    final today = await prayerService.getTodayPrayerTimes();
    if (today == null) return null;

    // Check if Fajr passed today
    final now = DateTime.now();
    final fajrToday = today.getFajrDateTime();

    if (now.isAfter(fajrToday)) {
      // Return tomorrow's Fajr 
      return today.fajr;
    }

    return today.fajr;
  } catch (e) {
    return null;
  }
}

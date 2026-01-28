import 'package:alarm_islamic/core/app_theme.dart';
import 'package:alarm_islamic/screens/alarm_list_screen.dart';
import 'package:alarm_islamic/services/location_service.dart';
import 'package:alarm_islamic/services/permission_service.dart';
import 'package:alarm_islamic/services/prayer_times_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// First launch screen - Setup location and fetch prayer times
class FirstLaunchScreen extends StatefulWidget {
  const FirstLaunchScreen({super.key});

  @override
  State<FirstLaunchScreen> createState() => _FirstLaunchScreenState();
}

class _FirstLaunchScreenState extends State<FirstLaunchScreen> {
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1026), Color(0xFF1A2347)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.goldGradient,
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    size: 50,
                    color: Color(0xFF0B1026),
                  ),
                ),

                const SizedBox(height: 32),

                // Welcome text
                Text(
                  'مرحباً في نَشُور',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.copyWith(color: AppTheme.gold),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  'منبه الصلاة الذكي',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.gold.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.gold, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        'نحتاج موقعك',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لتحديد أوقات الصلاة بدقة حسب منطقتك\nسنحمّل مواقيت شهر كامل للعمل بدون إنترنت',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Status message
                if (_statusMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _statusMessage,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.gold),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Loading or button
                if (_isLoading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _setupApp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: AppTheme.midnight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'ابدأ',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.midnight,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Setup app - request location and fetch prayer times
  Future<void> _setupApp() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      // 1. Request location permission
      setState(() => _statusMessage = 'طلب إذن الموقع...');
      final hasPermission = await PermissionService()
          .requestLocationPermission();

      if (!hasPermission) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'نحتاج إذن الموقع للمتابعة';
        });
        return;
      }

      // 2. Get location
      setState(() => _statusMessage = 'الحصول على موقعك...');
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();

      if (position == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'تعذر الحصول على الموقع';
        });
        return;
      }

      // 3. Get city name
      setState(() => _statusMessage = 'تحديد المدينة...');
      await locationService.getCityName(position);

      // 4. Fetch prayer times
      setState(() => _statusMessage = 'تحميل مواقيت الصلاة...');
      final prayerService = PrayerTimesService();
      final success = await prayerService.fetchAndSaveMonthlyPrayerTimes();

      if (!success) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'تعذر تحميل مواقيت الصلاة';
        });
        return;
      }

      // 5. Success - navigate to home
      setState(() => _statusMessage = 'تم بنجاح! ✅');
      await Future.delayed(const Duration(milliseconds: 500));

      Get.off(() => const AlarmListScreen());
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'حدث خطأ: $e';
      });
    }
  }
}

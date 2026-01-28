import 'dart:io';
import 'package:alarm_islamic/screens/onboarding/permission_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/app_theme.dart';
import 'services/hive_service.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'services/voice_service.dart';
import 'services/permission_service.dart';
import 'controllers/alarm_controller.dart';
import 'controllers/stats_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/settings_controller.dart';
import 'screens/alarm_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  await _initializeServices();

  runApp(const NashurApp());
}

/// Initialize all app services
Future<void> _initializeServices() async {
  try {
    // Initialize Hive
    await HiveService.init();
    print('✅ Hive initialized');

    // TEMPORARY: Clear alarms to fix migration crash
    await HiveService.clearAlarms();
    print('🧹 Alarms cleared to fix migration crash');

    // Initialize alarm service
    await AlarmService().init();
    print('✅ Alarm service initialized');

    // Initialize notifications
    await NotificationService().init();
    print('✅ Notification service initialized');

    // Initialize voice service
    await VoiceService().init();
    print('✅ Voice service initialized');

    // We don't request permissions here automatically anymore,
    // it will be handled by the PermissionScreen or splash check
  } catch (e) {
    print('❌ Service initialization error: $e');
  }
}

class NashurApp extends StatelessWidget {
  const NashurApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    final themeController = Get.put(ThemeController());
    final settingsController = Get.put(SettingsController());

    return ScreenUtilInit(
      designSize: const Size(360, 690), // Standard reference size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Obx(
          () => GetMaterialApp(
            title: 'نَشُور - Nashur',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode.value,
            locale: Locale(settingsController.locale.value),
            fallbackLocale: const Locale('ar'),
            home: const SplashScreen(),
            // Initialize controllers globally
            initialBinding: BindingsBuilder(() {
              Get.put(AlarmController());
              Get.put(StatsController());
            }),
          ),
        );
      },
    );
  }
}

/// Splash screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));

    // Check if we have all critical permissions
    final permService = PermissionService();
    final hasNotif = await permService.hasNotificationPermission();
    final hasMic = await permService.hasMicrophonePermission();
    final hasExact = await permService.hasExactAlarmPermission();

    if (hasNotif && hasMic && hasExact) {
      Get.off(() => AlarmListScreen());
    } else {
      Get.off(() => PermissionScreen());
    }
  }

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon placeholder (will be replaced with actual icon)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.goldGradient,
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  size: 60,
                  color: Color(0xFF0B1026),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'نَشُور',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = AppTheme.goldGradient.createShader(
                      const Rect.fromLTWH(0, 0, 200, 70),
                    ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nashur - Islamic Alarm',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

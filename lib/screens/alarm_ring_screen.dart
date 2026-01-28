import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alarm/alarm.dart' as alarm_pkg;
import 'package:vibration/vibration.dart';
import '../controllers/alarm_controller.dart';
import '../controllers/stats_controller.dart';
import '../services/voice_service.dart';
import '../models/alarm_model.dart';
import '../widgets/digital_clock.dart';
import '../widgets/mic_animation.dart';
import '../core/app_theme.dart';
import 'adhkar_screen.dart';

/// Alarm Ring Screen - Voice-only dismissal with smart snooze
class AlarmRingScreen extends StatefulWidget {
  final AlarmModel alarm;

  const AlarmRingScreen({super.key, required this.alarm});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with TickerProviderStateMixin {
  final _voiceService = VoiceService();
  final _alarmController = Get.find<AlarmController>();
  final _statsController = Get.find<StatsController>();

  bool _isListening = false;
  String _spokenText = '';
  String _feedbackMessage = 'انطق دعاء الاستيقاظ لإيقاف المنبه';
  bool _isAlarmDismissed = false;

  @override
  void initState() {
    super.initState();

    // Enter immersive mode
    _enterImmersiveMode();

    // Start custom vibration if not continuous
    _startVibrationPattern();

    // Auto-start voice recognition after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      _startListening();
    });
  }

  /// Start custom vibration pattern logic
  void _startVibrationPattern() async {
    if (widget.alarm.vibrationPattern == 'continuous')
      return; // Handled natively

    // Loop vibration while alarm is active
    while (!_isAlarmDismissed && mounted) {
      if (await Vibration.hasVibrator() == true) {
        switch (widget.alarm.vibrationPattern) {
          case 'pulse':
            Vibration.vibrate(pattern: [500, 200, 500, 200]);
            await Future.delayed(const Duration(milliseconds: 1400));
            break;
          case 'wave':
            Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
            await Future.delayed(const Duration(milliseconds: 2500));
            break;
          case 'knock':
            Vibration.vibrate(pattern: [0, 100, 100, 100, 100, 100]);
            await Future.delayed(const Duration(milliseconds: 1000));
            break;
          case 'sos':
            Vibration.vibrate(
              pattern: [
                0, 200, 100, 200, 100, 200, // S
                300, 600, 100, 600, 100, 600, // O
                300, 200, 100, 200, 100, 200, // S
              ],
            );
            await Future.delayed(const Duration(milliseconds: 4000));
            break;
          default:
            await Future.delayed(const Duration(seconds: 1)); // Backoff
            break;
        }
      } else {
        break; // No vibrator
      }
    }
  }

  /// Enter immersive mode (hide status/navigation bars)
  void _enterImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  /// Exit immersive mode
  void _exitImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  /// Stop alarm sound
  Future<void> _stopAlarmSound() async {
    // Stop custom vibration
    Vibration.cancel();

    // Alarm package handles audio automatically
    await alarm_pkg.Alarm.stop(widget.alarm.id.hashCode);
  }

  /// Start voice recognition
  Future<void> _startListening() async {
    if (_isAlarmDismissed) return;

    debugPrint('🎤 Checking microphone permission...');
    final hasPermission = await _voiceService.hasPermission();
    if (!hasPermission) {
      debugPrint('❌ Microphone permission denied');
      setState(() {
        _feedbackMessage = 'يرجى السماح بالوصول إلى الميكروفون';
      });
      return;
    }

    debugPrint('✅ Microphone permission granted');
    setState(() {
      _isListening = true;
      _feedbackMessage = 'استمع... انطق الدعاء الآن';
    });

    try {
      debugPrint('🎤 Starting voice recognition...');
      _voiceService.startListening(
        onResult: _onVoiceResult,
        onPartialResult: (text) {
          debugPrint('🎤 Partial: "$text"');
          setState(() {
            _spokenText = text;
            // UPDATE: Show helpful feedback instantly
            _feedbackMessage = _voiceService.getValidationFeedback(text);
          });
        },
      );
      debugPrint('✅ Voice recognition started successfully');
    } catch (e) {
      debugPrint('❌ Voice recognition error: $e');
      setState(() {
        _isListening = false;
        _feedbackMessage = 'خطأ في الميكروفون - جرب مرة أخرى';
      });

      // Retry after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        _startListening();
      });
    }
  }

  /// Handle voice recognition result
  void _onVoiceResult(String text) {
    debugPrint('🎤 Voice result received: "$text"');

    setState(() {
      _spokenText = text;
      _isListening = false;
    });

    // Validate dhikr
    final isValid = _voiceService.isValidDhikr(text);
    final feedback = _voiceService.getValidationFeedback(text);

    debugPrint('✅ Is valid: $isValid');
    debugPrint('💬 Feedback: $feedback');

    setState(() {
      _feedbackMessage = feedback;
    });

    if (isValid) {
      // Success! Dismiss alarm
      debugPrint('🎉 Valid dhikr! Dismissing alarm...');
      _dismissAlarm();
    } else {
      // Invalid - restart listening after 2 seconds
      debugPrint('❌ Invalid dhikr. Restarting listening...');
      Future.delayed(const Duration(seconds: 2), () {
        _startListening();
      });
    }
  }

  /// Dismiss alarm (voice success)
  Future<void> _dismissAlarm() async {
    if (_isAlarmDismissed) return;

    setState(() {
      _isAlarmDismissed = true;
    });

    // Stop alarm sound (alarm package handles this)
    await _stopAlarmSound();

    // Increment stats
    await _statsController.incrementWakeup();

    // Reset snooze count
    await _alarmController.resetSnooze(widget.alarm.id);

    // Exit immersive mode
    _exitImmersiveMode();

    // Show success message
    Get.snackbar(
      '✅ بارك الله فيك',
      'تم إيقاف المنبه بنجاح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.success,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );

    // Navigate to Adhkar or Home
    // Ask user if they want to read Adhkar
    Get.defaultDialog(
      title: 'تقبل الله طاعتكم',
      content: const Text(
        'هل ترغب في قراءة أذكار الصباح الآن؟',
        textAlign: TextAlign.center,
      ),
      backgroundColor: AppTheme.midnight,
      titleStyle: const TextStyle(color: AppTheme.gold),
      middleTextStyle: const TextStyle(color: Colors.white),
      textConfirm: 'نعم',
      textCancel: 'لاحقاً',
      confirmTextColor: AppTheme.midnight,
      cancelTextColor: AppTheme.textSecondary,
      buttonColor: AppTheme.gold,
      onConfirm: () {
        Get.back(); // Close dialog
        Get.off(
          () => const AdhkarScreen(),
        ); // Navigate to Adhkar, replacing Ring
      },
      onCancel: () {
        Get.back(); // Close dialog
        Get.back(); // Close Ring screen
      },
      barrierDismissible: false,
    );
  }

  /// Snooze alarm
  Future<void> _snoozeAlarm() async {
    if (!widget.alarm.canSnooze) return;

    // Stop current alarm sound
    await _stopAlarmSound();

    // Call snooze in controller (will reschedule using AlarmService)
    await _alarmController.snoozeAlarm(widget.alarm.id);

    // Exit immersive mode
    _exitImmersiveMode();

    // Navigate back
    Get.back();
  }

  @override
  void dispose() {
    _stopAlarmSound();
    _exitImmersiveMode();
    _voiceService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return PopScope(
      canPop: false, // BLOCK back button
      onPopInvokedWithResult: (didPop, result) {
        // Do nothing - user CANNOT exit
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: AppTheme.midnight,
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
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section: Time
                  Column(
                    children: [
                      Text(
                        'منبه النشور',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppTheme.gold, fontSize: 34.sp),
                      ),
                      SizedBox(height: 16.h),
                      if (widget.alarm.label.isNotEmpty)
                        Text(
                          widget.alarm.label,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 20.sp,
                              ),
                        ),
                    ],
                  ),

                  // Middle section: Large Clock
                  DigitalClock(
                    hour: now.hour,
                    minute: now.minute,
                    second: now.second,
                    showSeconds: true,
                    fontSize: 84.sp,
                  ),

                  // Voice section
                  Column(
                    children: [
                      // Instruction text
                      Container(
                        height: 80.h,
                        alignment: Alignment.center,
                        child: Text(
                          _feedbackMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 24.sp,
                                color: _feedbackMessage.contains('✅')
                                    ? AppTheme.success
                                    : AppTheme.textPrimary,
                              ),
                        ),
                      ),
                      SizedBox(height: 32.h),

                      // Mic animation (Long Press to Dismiss)
                      GestureDetector(
                        onLongPress: () {
                          // Feedback
                          HapticFeedback.heavyImpact();
                          _dismissAlarm();
                        },
                        onTap: () {
                          // Restart listening manually if tapped
                          HapticFeedback.lightImpact();
                          _startListening();
                        },
                        child: Column(
                          children: [
                            MicAnimation(
                              isListening: _isListening,
                              size: 100.w,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'اضغط مطولاً للإيقاف الاضطراري',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.5),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Spoken text display
                      if (_spokenText.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            _spokenText,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16.sp,
                                ),
                          ),
                        ),
                    ],
                  ),

                  // Bottom section: Snooze button (if available)
                  if (widget.alarm.canSnooze)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: _snoozeAlarm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cardBg,
                            foregroundColor: AppTheme.gold,
                            padding: EdgeInsets.symmetric(
                              horizontal: 48.w,
                              vertical: 16.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.r),
                              side: BorderSide(
                                color: AppTheme.gold.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.snooze, size: 24.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'غفوة (${widget.alarm.snoozeDuration} دقيقة)',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontSize: 16.sp),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'محاولات متبقية: ${3 - widget.alarm.snoozeCount}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(fontSize: 12.sp),
                        ),
                      ],
                    )
                  else
                    // No more snooze - show warning
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.error.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '⚠️ استخدمت كل محاولات الغفوة\nيجب نطق الدعاء لإيقاف المنبه',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.error,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

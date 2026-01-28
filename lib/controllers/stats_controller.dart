import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/app_theme.dart';
import '../models/stats_model.dart';
import '../services/hive_service.dart';

/// Statistics controller for tracking user progress
class StatsController extends GetxController {
  // Observable stats
  final Rx<StatsModel> stats = StatsModel().obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  /// Load stats from Hive
  void loadStats() {
    stats.value = HiveService.getStats();
  }

  /// Increment wake-up counter (called when user says dhikr successfully)
  Future<void> incrementWakeup() async {
    final now = DateTime.now();
    final updatedStats = stats.value.incrementWakeup(now);
    
    stats.value = updatedStats;
    await HiveService.saveStats(updatedStats);

    // Show celebration message
    final streak = updatedStats.currentStreak;
    if (streak == 1) {
      _showAchievementDialog('🌱 رائع!', 'بدأت سلسلة جديدة من الاستيقاظ لصلاة الفجر!');
    } else if (streak == 7) {
      _showAchievementDialog('🔥 مذهل!', 'أتممت أسبوعاً كاملاً من المواظبة على صلاة الفجر!');
    } else if (streak == 30) {
      _showAchievementDialog('👑 إنجاز ملكي!', 'لقد صمدت لمدة شهر كامل! أنت بالفعل قدوة.');
    } else if (streak % 100 == 0) {
      _showAchievementDialog('✨ أسطوري!', '$streak يوماً متتالياً من الصدق مع الله.');
    }
  }

  void _showAchievementDialog(String title, String message) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1026), Color(0xFF1A2347)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.gold.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨ إنجاز جديد ✨', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                title,
                style: Get.textTheme.headlineMedium?.copyWith(color: AppTheme.gold, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.midnight,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('الحمد لله', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reset streak (for testing)
  Future<void> resetStreak() async {
    final updatedStats = stats.value.resetStreak();
    stats.value = updatedStats;
    await HiveService.saveStats(updatedStats);

    Get.snackbar(
      'تم',
      'تم إعادة تعيين السلسلة',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Clear all stats (for testing)
  Future<void> clearStats() async {
    stats.value = StatsModel();
    await HiveService.saveStats(StatsModel());

    Get.snackbar(
      'تم',
      'تم مسح جميع الإحصائيات',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Computed properties for UI

  int get currentStreak => stats.value.currentStreak;
  int get totalWakeups => stats.value.totalWakeups;
  DateTime? get lastWakeupTime => stats.value.lastWakeupTime;
  String get streakEmoji => stats.value.streakEmoji;
  bool get wokeUpToday => stats.value.wokeUpToday;

  /// Get weekly progress (last 7 days)
  List<bool> get weeklyProgress => stats.value.getWeeklyProgress();
  
  /// Get monthly progress (last 30 days)
  List<bool> get monthlyProgress {
    final now = DateTime.now();
    final results = <bool>[];
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      results.add(stats.value.weeklyLog[key] ?? false);
    }
    return results;
  }

  /// Get chart data for the last 7 days
  List<double> get weeklyChartData {
    final now = DateTime.now();
    final results = <double>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      results.add((stats.value.weeklyLog[key] ?? false) ? 1.0 : 0.0);
    }
    return results;
  }
  
  /// Get achievement status
  List<Map<String, dynamic>> get achievements {
    final s = stats.value;
    return [
      {
        'title': 'البداية',
        'desc': 'أول استيقاظ للفجر',
        'icon': '🌱',
        'unlocked': s.totalWakeups >= 1,
      },
      {
        'title': 'الأسبوع الأول',
        'desc': 'استيقاظ لمدة 7 أيام متتالية',
        'icon': '🔥',
        'unlocked': s.currentStreak >= 7,
      },
      {
        'title': 'الالتزام',
        'desc': '30 يوماً من الاستيقاظ',
        'icon': '⭐',
        'unlocked': s.totalWakeups >= 30,
      },
      {
        'title': 'أسطورة الفجر',
        'desc': '100 يوم من الاستيقاظ',
        'icon': '👑',
        'unlocked': s.totalWakeups >= 100,
      },
      {
        'title': 'المثابر',
        'desc': '300 يوم من الاستيقاظ',
        'icon': '🏆',
        'unlocked': s.totalWakeups >= 300,
      },
    ];
  }

  /// Get streak percentage (for progress ring)
  double getStreakPercentage({int maxStreak = 30}) {
    if (currentStreak == 0) return 0.0;
    return (currentStreak / maxStreak).clamp(0.0, 1.0);
  }

  /// Get current user rank based on total wakeups
  String get userRank {
    final total = totalWakeups;
    if (total == 0) return 'مبتدئ';
    if (total < 10) return 'مواظب ناشئ';
    if (total < 30) return 'ملتزم بالفجر';
    if (total < 100) return 'مجاهد الفجر';
    if (total < 300) return 'خادم بيت الله';
    return 'حافظ صلاة الفجر';
  }

  /// Get numerical world rank (simulated)
  int get worldRank {
    // Simulated rank based on total wakeups
    // More wakeups = lower rank number (closer to #1)
    final baseRank = 1000000;
    final reduction = totalWakeups * 50 + currentStreak * 200;
    return (baseRank - reduction).clamp(1, baseRank);
  }

  /// Get next rank progress
  double get rankProgress {
    final total = totalWakeups;
    if (total < 10) return total / 10;
    if (total < 30) return (total - 10) / 20;
    if (total < 100) return (total - 30) / 70;
    if (total < 300) return (total - 100) / 200;
    return 1.0;
  }

  /// Get motivational message based on streak
  String get motivationalMessage {
    if (currentStreak == 0) {
      return 'ابدأ رحلتك اليوم!';
    } else if (currentStreak < 3) {
      return 'استمر! أنت في البداية';
    } else if (currentStreak < 7) {
      return 'رائع! استمر في التقدم';
    } else if (currentStreak < 30) {
      return 'ممتاز! أنت تقوم بعمل رائع';
    } else if (currentStreak < 100) {
      return 'مذهل! أنت بطل حقيقي';
    } else {
      return 'أسطوري! أنت مصدر إلهام';
    }
  }

  /// Format last wake-up time
  String get formattedLastWakeup {
    if (lastWakeupTime == null) return 'لم تستيقظ بعد';

    final now = DateTime.now();
    final diff = now.difference(lastWakeupTime!);

    if (diff.inDays == 0) {
      return 'اليوم';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    } else {
      return 'منذ ${(diff.inDays / 7).floor()} أسابيع';
    }
  }
}

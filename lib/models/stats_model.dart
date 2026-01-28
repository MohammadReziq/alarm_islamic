import 'package:hive/hive.dart';

part 'stats_model.g.dart';

/// Statistics model for tracking user progress (Hive-persisted)
@HiveType(typeId: 1)
class StatsModel {
  @HiveField(0)
  final int currentStreak; // Days of consecutive wake-ups

  @HiveField(1)
  final int totalWakeups; // Lifetime successful dismissals

  @HiveField(2)
  final DateTime? lastWakeupTime; // Last successful dhikr time

  @HiveField(3)
  final Map<String, bool> weeklyLog; // Date → completed (YYYY-MM-DD)

  StatsModel({
    this.currentStreak = 0,
    this.totalWakeups = 0,
    this.lastWakeupTime,
    Map<String, bool>? weeklyLog,
  }) : weeklyLog = weeklyLog ?? {};

  /// Increment wake-up counter and update streak
  StatsModel incrementWakeup(DateTime wakeupTime) {
    final today = _dateKey(wakeupTime);
    final yesterday = _dateKey(wakeupTime.subtract(const Duration(days: 1)));

    // Calculate new streak
    int newStreak = currentStreak;

    if (lastWakeupTime == null) {
      // First wake-up ever
      newStreak = 1;
    } else {
      final lastDate = _dateKey(lastWakeupTime!);

      if (lastDate == today) {
        // Already woke up today, don't increment streak
        newStreak = currentStreak;
      } else if (lastDate == yesterday) {
        // Consecutive day
        newStreak = currentStreak + 1;
      } else {
        // Streak broken, reset to 1
        newStreak = 1;
      }
    }

    // Update weekly log
    final updatedLog = Map<String, bool>.from(weeklyLog);
    updatedLog[today] = true;

    // Keep last 365 days in log (year view)
    final cutoffDate = wakeupTime.subtract(const Duration(days: 365));
    updatedLog.removeWhere((key, _) {
      final date = DateTime.parse(key);
      return date.isBefore(cutoffDate);
    });

    return StatsModel(
      currentStreak: newStreak,
      totalWakeups: totalWakeups + 1,
      lastWakeupTime: wakeupTime,
      weeklyLog: updatedLog,
    );
  }

  /// Reset streak (when user misses a day)
  StatsModel resetStreak() {
    return StatsModel(
      currentStreak: 0,
      totalWakeups: totalWakeups,
      lastWakeupTime: lastWakeupTime,
      weeklyLog: weeklyLog,
    );
  }

  /// Get weekly completion status (last 7 days)
  List<bool> getWeeklyProgress() {
    final now = DateTime.now();
    final results = <bool>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = _dateKey(date);
      results.add(weeklyLog[key] ?? false);
    }

    return results;
  }

  /// Check if woke up today
  bool get wokeUpToday {
    if (lastWakeupTime == null) return false;
    final today = _dateKey(DateTime.now());
    final lastDate = _dateKey(lastWakeupTime!);
    return today == lastDate;
  }

  /// Get streak emoji based on count
  String get streakEmoji {
    if (currentStreak == 0) return '💤';
    if (currentStreak < 3) return '🌱';
    if (currentStreak < 7) return '🔥';
    if (currentStreak < 30) return '⭐';
    return '👑'; // 30+ days
  }

  /// Helper: Convert DateTime to YYYY-MM-DD string
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Copy with modifications
  StatsModel copyWith({
    int? currentStreak,
    int? totalWakeups,
    DateTime? lastWakeupTime,
    Map<String, bool>? weeklyLog,
  }) {
    return StatsModel(
      currentStreak: currentStreak ?? this.currentStreak,
      totalWakeups: totalWakeups ?? this.totalWakeups,
      lastWakeupTime: lastWakeupTime ?? this.lastWakeupTime,
      weeklyLog: weeklyLog ?? this.weeklyLog,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'totalWakeups': totalWakeups,
    'lastWakeupTime': lastWakeupTime?.toIso8601String(),
    'weeklyLog': weeklyLog,
  };

  factory StatsModel.fromJson(Map<String, dynamic> json) => StatsModel(
    currentStreak: json['currentStreak'] ?? 0,
    totalWakeups: json['totalWakeups'] ?? 0,
    lastWakeupTime: json['lastWakeupTime'] != null ? DateTime.parse(json['lastWakeupTime']) : null,
    weeklyLog: Map<String, bool>.from(json['weeklyLog'] ?? {}),
  );

  @override
  String toString() {
    return 'StatsModel(streak: $currentStreak, total: $totalWakeups, lastWakeup: $lastWakeupTime)';
  }
}

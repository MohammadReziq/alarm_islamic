import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/stats_controller.dart';
import '../widgets/gold_card.dart';
import '../core/app_theme.dart';
import 'challenge_screen.dart';

/// Dashboard Screen - Local stats and analytics
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statsController = Get.put(StatsController());

    return Scaffold(
      backgroundColor: AppTheme.midnight,
      appBar: AppBar(
        title: const Text('الإحصائيات'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1026), Color(0xFF1A2347)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current streak with gold ring
            _buildStreakCard(statsController),

            const SizedBox(height: 16),

            // Total wakeups
            _buildTotalWakeupsCard(statsController),

            const SizedBox(height: 16),

            // Activity Chart
            _buildActivityChartCard(statsController),

            const SizedBox(height: 16),

            // Fajr Challenge Button
            ElevatedButton.icon(
              onPressed: () => Get.to(() => const ChallengeScreen()),
              icon: const Icon(Icons.emoji_events, color: AppTheme.midnight),
              label: const Text('انضم لتحدي صلاة الفجر (عالمياً) 🔥'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.midnight,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),

            const SizedBox(height: 16),
            
            // Achievements
            _buildAchievementsCard(statsController),

            const SizedBox(height: 16),

            // Last wakeup
            _buildLastWakeupCard(statsController),
          ],
        ),
      ),
    );
  }

  /// Streak card with circular progress indicator
  Widget _buildStreakCard(StatsController controller) {
    return Obx(() {
      final streak = controller.currentStreak;
      final emoji = controller.streakEmoji;
      final percentage = controller.getStreakPercentage(maxStreak: 30);
      final message = controller.motivationalMessage;

      return GoldCard(
        child: Column(
          children: [
            Text(
              'سلسلة الاستيقاظ',
              style: Get.textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Circular progress indicator
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 12,
                      valueColor: AlwaysStoppedAnimation(
                        AppTheme.textSecondary.withOpacity(0.1),
                      ),
                    ),
                  ),

                  // Progress circle (gold)
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOut,
                      tween: Tween(begin: 0.0, end: percentage),
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 12,
                          valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
                        );
                      },
                    ),
                  ),

                  // Center content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$streak',
                        style: Get.textTheme.displayLarge?.copyWith(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 56,
                        ),
                      ),
                      Text(
                        'يوم',
                        style: Get.textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              message,
              style: Get.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    });
  }

  /// Total wakeups card
  Widget _buildTotalWakeupsCard(StatsController controller) {
    return Obx(() {
      final total = controller.totalWakeups;

      return GoldCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي الاستيقاظات',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$total',
                  style: Get.textTheme.displaySmall?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold, width: 2),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48,
                color: AppTheme.gold,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Activity Chart Card (Weekly Bar Chart)
  Widget _buildActivityChartCard(StatsController controller) {
    return Obx(() {
      final weeklyData = controller.weeklyChartData;
      
      return GoldCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'نشاط الأسبوع الحالي',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Icon(Icons.bar_chart, color: AppTheme.gold.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1.0,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
                          int index = value.toInt();
                          if (index >= 0 && index < days.length) {
                             return Text(
                              days[index],
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 22,
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(weeklyData.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weeklyData[i],
                          color: AppTheme.gold,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 1.0,
                            color: AppTheme.cardBg,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Achievements Card
  Widget _buildAchievementsCard(StatsController controller) {
    return Obx(() {
      final achievements = controller.achievements;

      return GoldCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الإنجازات',
              style: Get.textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: achievements.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = achievements[index];
                final unlocked = item['unlocked'] as bool;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: unlocked ? AppTheme.gold.withOpacity(0.1) : AppTheme.cardBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: unlocked ? AppTheme.gold.withOpacity(0.5) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: unlocked ? AppTheme.gold : AppTheme.cardBg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            item['icon'],
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: TextStyle(
                                color: unlocked ? Colors.white : AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                                decoration: unlocked ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              item['desc'],
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (unlocked)
                        const Icon(Icons.check_circle, color: AppTheme.gold)
                      else
                        Icon(Icons.lock, color: AppTheme.textSecondary.withOpacity(0.3)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  /// Last wakeup card
  Widget _buildLastWakeupCard(StatsController controller) {
    return Obx(() {
      final lastWakeup = controller.formattedLastWakeup;
      final wokeUpToday = controller.wokeUpToday;

      return GoldCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'آخر استيقاظ',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lastWakeup,
                  style: Get.textTheme.titleLarge?.copyWith(
                    color: wokeUpToday ? AppTheme.success : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(
              wokeUpToday ? Icons.wb_sunny : Icons.history,
              size: 40,
              color: wokeUpToday ? AppTheme.success : AppTheme.textSecondary,
            ),
          ],
        ),
      );
    });
  }
}

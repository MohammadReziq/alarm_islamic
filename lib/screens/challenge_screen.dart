import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/stats_controller.dart';
import '../widgets/gold_card.dart';
import '../core/app_theme.dart';

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statsController = Get.find<StatsController>();

    return Scaffold(
      backgroundColor: AppTheme.midnight,
      appBar: AppBar(
        title: const Text('تحدي صلاة الفجر 🏆'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1026), Color(0xFF1A2347)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Rank Box
            _buildUserRankHeader(statsController),
            
            const SizedBox(height: 24),
            
            // Leaderboard Title
            Text(
              'أوائل المجاهدين (عالمياً) 🌍',
              style: Get.textTheme.titleLarge?.copyWith(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Mocked Leaderboard
            _buildLeaderboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRankHeader(StatsController controller) {
    return Obx(() {
      final streak = controller.currentStreak;
      final total = controller.totalWakeups;
      final rankName = controller.userRank;
      final rankNumber = controller.worldRank;

      return GoldCard(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.gold,
                  child: Icon(Icons.person, size: 50, color: AppTheme.midnight),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rankName,
              style: Get.textTheme.titleLarge?.copyWith(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem('السلسلة', '$streak 🔥'),
                const SizedBox(width: 32),
                _buildStatItem('الإجمالي', '$total 🕌'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
              ),
              child: Text(
                'أنت في المركز #${rankNumber.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} عالمياً',
                style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard() {
    final mockData = [
      {'name': 'عبدالرحمن م.', 'streak': 842, 'rank': '1', 'avatar': '🕌'},
      {'name': 'فاطمة الزهراء', 'streak': 765, 'rank': '2', 'avatar': '⭐'},
      {'name': 'أحمد إبراهيم', 'streak': 712, 'rank': '3', 'avatar': '🔥'},
      {'name': 'سارة خالد', 'streak': 689, 'rank': '4', 'avatar': '🌱'},
      {'name': 'يوسف علي', 'streak': 654, 'rank': '5', 'avatar': '✨'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mockData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = mockData[index];
        final isTop3 = index < 3;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isTop3 ? AppTheme.gold.withOpacity(0.1) : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTop3 ? AppTheme.gold : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                '#${user['rank']}',
                style: TextStyle(
                  color: isTop3 ? AppTheme.gold : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                backgroundColor: AppTheme.midnight,
                child: Text(user['avatar']! as String),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  user['name']! as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${user['streak']} يوم',
                style: const TextStyle(color: AppTheme.gold),
              ),
            ],
          ),
        );
      },
    );
  }
}

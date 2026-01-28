import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/adhkar.dart';
import '../core/app_theme.dart';
import '../widgets/gold_card.dart';

class AdhkarScreen extends StatefulWidget {
  const AdhkarScreen({super.key});

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  // Track remaining counts for each dhikr
  late List<int> _counts;

  @override
  void initState() {
    super.initState();
    _counts = AdhkarData.morning.map((d) => d.count).toList();
  }

  void _decrementCount(int index) {
    if (_counts[index] > 0) {
      setState(() {
        _counts[index]--;
      });
      
      if (_counts[index] == 0) {
        // Haptic or sound feedback?
      }
    }
  }

  bool get _allCompleted => _counts.every((c) => c == 0);

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_counts.reduce((a, b) => a + b) / 
        AdhkarData.morning.map((d) => d.count).reduce((a, b) => a + b));

    return Scaffold(
      backgroundColor: AppTheme.midnight,
      appBar: AppBar(
        title: const Text('أذكار الصباح'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1026), Color(0xFF1A2347)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.midnight,
              color: AppTheme.gold,
              minHeight: 4,
            ),
            
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: AdhkarData.morning.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final dhikr = AdhkarData.morning[index];
                  final count = _counts[index];
                  final isCompleted = count == 0;

                  return GestureDetector(
                    onTap: () => _decrementCount(index),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isCompleted ? 0.5 : 1.0,
                      child: GoldCard(
                        child: Column(
                          children: [
                            Text(
                              dhikr.text,
                              style: Get.textTheme.titleMedium?.copyWith(
                                color: isCompleted ? AppTheme.textSecondary : Colors.white,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            
                            if (dhikr.benefit != null) ...[
                              Text(
                                dhikr.benefit!,
                                style: Get.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.gold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Counter Button
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isCompleted ? AppTheme.success.withOpacity(0.2) : AppTheme.midnight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCompleted ? AppTheme.success : AppTheme.gold,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  isCompleted ? 'تم ✓' : '$count / ${dhikr.count}',
                                  style: TextStyle(
                                    color: isCompleted ? AppTheme.success : AppTheme.gold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Completion Button
            if (_allCompleted)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.midnight,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text('إنهاء'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:vibration/vibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../controllers/alarm_controller.dart';
import '../controllers/stats_controller.dart';
import '../models/alarm_model.dart';
import '../widgets/gold_card.dart';
import '../services/prayer_times_service.dart';
import '../core/app_theme.dart';
import '../models/sound_library.dart';
import '../services/permission_service.dart';

/// Alarm Edit Screen - Create/Edit alarm (Samsung Clock style)
class AlarmEditScreen extends StatefulWidget {
  final AlarmModel? alarm; // null = create new alarm

  const AlarmEditScreen({super.key, this.alarm});

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  final _alarmController = Get.find<AlarmController>();
  final _labelController = TextEditingController();

  late int _selectedHour;
  late int _selectedMinute;
  late List<int> _selectedDays;
  late String _selectedSound;
  late String _selectedVibration;

  final List<String> _weekDaysArabic = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];
  final List<String> _weekDaysFull = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.alarm != null) {
      // Edit mode
      _selectedHour = widget.alarm!.hour;
      _selectedMinute = widget.alarm!.minute;
      _selectedDays = List.from(widget.alarm!.repeatDays);
      _selectedSound = widget.alarm!.soundPath;
      _selectedVibration = widget.alarm!.vibrationPattern;
      _labelController.text = widget.alarm!.label;
    } else {
      // Create mode - defaults
      final now = DateTime.now();
      _selectedHour = now.hour;
      _selectedMinute = now.minute;
      _selectedDays = [];
      _selectedSound = 'assets/sounds/alarms_sound/makkah.mp3';
      _selectedVibration = 'continuous';
      
      // Show Smart Fajr Suggestion dialog after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSmartFajrSuggestionDialog();
      });
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _saveAlarm() async {
    // Ensure DND access for reliable ringing
    if (await PermissionService().hasDNDAccess() == false) {
      final granted = await PermissionService().requestDNDAccess();
      if (!granted) return; // Optional: block saving or just proceed with warning
    }
    if (widget.alarm != null) {
      // Update existing
      final updatedAlarm = widget.alarm!.copyWith(
        hour: _selectedHour,
        minute: _selectedMinute,
        repeatDays: _selectedDays,
        label: _labelController.text.trim(),
        soundPath: _selectedSound,
        vibrationPattern: _selectedVibration,
      );
      _alarmController.updateAlarm(updatedAlarm);
    } else {
      // Create new
      _alarmController.addAlarm(
        hour: _selectedHour,
        minute: _selectedMinute,
        label: _labelController.text.trim(),
        repeatDays: _selectedDays,
        soundPath: _selectedSound,
        vibrationPattern: _selectedVibration,
      );
    }

    Get.back();
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
        _selectedDays.sort();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.midnight,
      appBar: AppBar(
        title: Text(widget.alarm != null ? 'تعديل المنبه' : 'منبه جديد'),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: Text(
              'حفظ',
              style: Get.textTheme.titleMedium?.copyWith(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
          padding: EdgeInsets.all(16.w),
          children: [
            // Smart Fajr Calculator
            _buildSmartFajrCalculator(),

            SizedBox(height: 16.h),

            // Time picker
            _buildTimePicker(),

            SizedBox(height: 24.h),

            // Repeat days selector
            _buildDaySelector(),

            SizedBox(height: 24.h),

            // Label input
            _buildLabelInput(),

            SizedBox(height: 24.h),

            // Sound selector (placeholder - will use default for now)
            _buildSoundSelector(),

            SizedBox(height: 24.h),

            // Vibration selector
            _buildVibrationSelector(),
          ],
        ),
      ),
    );
  }

  /// Time picker (large wheel-style display)
  Widget _buildTimePicker() {
    return GoldCard(
      child: Column(
        children: [
          Text(
            'الوقت',
            style: Get.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour picker
              _buildNumberPicker(
                value: _selectedHour,
                minValue: 0,
                maxValue: 23,
                onChanged: (value) {
                  setState(() {
                    _selectedHour = value;
                  });
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  ':',
                  style: Get.textTheme.displayLarge?.copyWith(
                    color: AppTheme.gold,
                    fontSize: 84.sp,
                  ),
                ),
              ),
              // Minute picker
              _buildNumberPicker(
                value: _selectedMinute,
                minValue: 0,
                maxValue: 59,
                onChanged: (value) {
                  setState(() {
                    _selectedMinute = value;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            _selectedHour < 12 ? 'صباحاً' : 'مساءً',
            style: Get.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  /// Number picker widget
  Widget _buildNumberPicker({
    required int value,
    required int minValue,
    required int maxValue,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(Icons.keyboard_arrow_up, size: 28.sp),
          color: AppTheme.gold,
          onPressed: () {
            final newValue = value < maxValue ? value + 1 : minValue;
            onChanged(newValue);
          },
        ),
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.gold, width: 2),
          ),
          child: Center(
            child: Text(
              value.toString().padLeft(2, '0'),
              style: Get.textTheme.displayMedium?.copyWith(
                color: AppTheme.gold,
                fontWeight: FontWeight.bold,
                fontSize: 40.sp,
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.keyboard_arrow_down, size: 28.sp),
          color: AppTheme.gold,
          onPressed: () {
            final newValue = value > minValue ? value - 1 : maxValue;
            onChanged(newValue);
          },
        ),
      ],
    );
  }

  /// Day selector (circles like Samsung Clock)
  Widget _buildDaySelector() {
    return GoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تكرار',
            style: Get.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final isSelected = _selectedDays.contains(index);
              return GestureDetector(
                onTap: () => _toggleDay(index),
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppTheme.gold : AppTheme.cardBg,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.gold
                          : AppTheme.textSecondary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _weekDaysArabic[index],
                      style: Get.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? AppTheme.midnight
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_selectedDays.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              _selectedDays.length == 7
                  ? 'كل يوم'
                  : _selectedDays.map((d) => _weekDaysFull[d]).join('، '),
              style: Get.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Label input field
  Widget _buildLabelInput() {
    return GoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اسم المنبه',
            style: Get.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _labelController,
            style: Get.textTheme.bodyLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: 'صلاة الفجر، العمل، إلخ...',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 14.sp,
              ),
              filled: true,
              fillColor: AppTheme.midnight.withOpacity(0.5),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppTheme.gold.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppTheme.gold.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppTheme.gold, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sound selector
  Widget _buildSoundSelector() {
    final currentSound = SoundLibrary.getSoundByPath(_selectedSound);

    return GestureDetector(
      onTap: _showSoundSelectorDialog,
      child: GoldCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'صوت المنبه',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  currentSound.name,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gold,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  currentSound.sheikhName,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary.withOpacity(0.5),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: AppTheme.gold, size: 16.sp),
          ],
        ),
      ),
    );
  }

  /// Show sound selector dialog
  void _showSoundSelectorDialog() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        padding: const EdgeInsets.only(top: 20),
        decoration: const BoxDecoration(
          color: AppTheme.midnight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.gold, width: 2)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'اختر الصوت',
                    style: Get.textTheme.titleLarge?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.textSecondary, height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: SoundLibrary.availableSounds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final sound = SoundLibrary.availableSounds[index];
                  final isSelected = sound.assetPath == _selectedSound;
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.gold.withOpacity(0.15) : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.gold : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _selectedSound = sound.assetPath;
                        });
                        Get.back();
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.midnight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: isSelected ? AppTheme.gold : AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        sound.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        sound.sheikhName,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.gold) : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Vibration selector
  Widget _buildVibrationSelector() {
    final patterns = [
      {'id': 'continuous', 'name': 'مستمر', 'icon': Icons.vibration},
      {'id': 'pulse', 'name': 'نبض', 'icon': Icons.favorite},
      {'id': 'wave', 'name': 'موجة', 'icon': Icons.waves},
      {'id': 'knock', 'name': 'طرق', 'icon': Icons.touch_app},
      {'id': 'sos', 'name': 'SOS', 'icon': Icons.warning},
    ];

    return GoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نمط الاهتزاز',
            style: Get.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 80.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: patterns.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (context, index) {
                final pattern = patterns[index];
                final isSelected = _selectedVibration == pattern['id'];

                return GestureDetector(
                  onTap: () {
                    setState(
                      () => _selectedVibration = pattern['id'] as String,
                    );
                    _previewVibration(pattern['id'] as String);
                  },
                  child: Container(
                    width: 70.w,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.gold : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.gold
                            : AppTheme.textSecondary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          pattern['icon'] as IconData,
                          color: isSelected
                              ? AppTheme.midnight
                              : AppTheme.textSecondary,
                          size: 24.sp,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          pattern['name'] as String,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.midnight
                                : AppTheme.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Preview vibration pattern
  void _previewVibration(String patternId) async {
    if (await Vibration.hasVibrator() != true) return;

    switch (patternId) {
      case 'pulse':
        Vibration.vibrate(pattern: [500, 200, 500, 200]);
        break;
      case 'wave':
        Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
        break;
      case 'knock':
        Vibration.vibrate(pattern: [0, 100, 100, 100, 100, 100]);
        break;
      case 'sos':
        Vibration.vibrate(
          pattern: [
            0, 200, 100, 200, 100, 200, // S
            300, 600, 100, 600, 100, 600, // O
            300, 200, 100, 200, 100, 200, // S
          ],
        );
        break;
      case 'continuous':
      default:
        Vibration.vibrate(duration: 500);
        break;
    }
  }

  /// Show Smart Fajr Suggestion Dialog when creating a new alarm
  Future<void> _showSmartFajrSuggestionDialog() async {
    final prayerService = PrayerTimesService();
    final hasPrayerTimes = await prayerService.hasPrayerTimes();
    
    if (!hasPrayerTimes) return; // No prayer times available
    
    final suggestions = await prayerService.getSuggestedFajrAlarmTimes();
    if (suggestions.isEmpty) return;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1026), Color(0xFF1A2347)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.gold.withOpacity(0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wb_twilight, color: Color(0xFF0B1026), size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'منبه صلاة الفجر 🕌',
                      style: Get.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF0B1026),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'هل تريد ضبط منبه لصلاة الفجر؟',
                      style: Get.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر الوقت المناسب لك:',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // First Adhan Section
                    _buildAdhanSection(
                      title: '📍 الأذان الأول',
                      suggestions: suggestions.where((s) => s.isFirstAdhan).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Second Adhan Section
                    _buildAdhanSection(
                      title: '🕌 أذان الفجر (الثاني)',
                      suggestions: suggestions.where((s) => !s.isFirstAdhan).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Skip button
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'لا، شكراً - سأضبطه يدوياً',
                        style: TextStyle(
                          color: AppTheme.textSecondary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Build Adhan section with suggestions
  Widget _buildAdhanSection({
    required String title,
    required List<FajrAlarmSuggestion> suggestions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Get.textTheme.titleSmall?.copyWith(
            color: AppTheme.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...suggestions.map((suggestion) => _buildSuggestionTile(suggestion)),
      ],
    );
  }

  /// Build suggestion tile
  Widget _buildSuggestionTile(FajrAlarmSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectFajrSuggestion(suggestion),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: suggestion.isRecommended 
                  ? AppTheme.gold.withOpacity(0.15) 
                  : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: suggestion.isRecommended 
                    ? AppTheme.gold 
                    : AppTheme.textSecondary.withOpacity(0.2),
                width: suggestion.isRecommended ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.midnight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    suggestion.formattedTime,
                    style: Get.textTheme.titleMedium?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.labelShort,
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: suggestion.isRecommended 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                        ),
                      ),
                      if (suggestion.isRecommended)
                        Text(
                          '⭐ الأفضل',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: suggestion.isRecommended 
                      ? AppTheme.gold 
                      : AppTheme.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle suggestion selection
  void _selectFajrSuggestion(FajrAlarmSuggestion suggestion) {
    Get.back(); // Close dialog
    
    setState(() {
      _selectedHour = suggestion.time.hour;
      _selectedMinute = suggestion.time.minute;
      _labelController.text = suggestion.alarmLabel;
    });

    Get.snackbar(
      'تم الضبط 🕌',
      'تم تعيين الوقت: ${suggestion.formattedTime}',
      backgroundColor: AppTheme.gold,
      colorText: AppTheme.midnight,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Smart Fajr Calculator Widget
  Widget _buildSmartFajrCalculator() {
    return FutureBuilder<bool>(
      future: PrayerTimesService().hasPrayerTimes(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();

        return GoldCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wb_twilight, color: AppTheme.gold),
                  const SizedBox(width: 8),
                  Text(
                    'مساعد الفجر الذكي 🕌',
                    style: Get.textTheme.titleMedium?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'اضبط المنبه تلقائياً بناءً على:',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Option 1: Second Adhan (Standard Fajr)
              ElevatedButton.icon(
                onPressed: () => _showFajrOptions(isFirstAdhan: false),
                icon: const Icon(Icons.access_time_filled),
                label: const Text('أذان الفجر (الثاني)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.midnight,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

              const SizedBox(height: 8),

              // Option 2: First Adhan (20 mins before)
              OutlinedButton.icon(
                onPressed: () => _showFajrOptions(isFirstAdhan: true),
                icon: const Icon(Icons.timelapse),
                label: const Text('الأذان الأول (قبل 20د)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.gold,
                  side: const BorderSide(color: AppTheme.gold),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show Fajr Adjustment Options
  void _showFajrOptions({required bool isFirstAdhan}) async {
    final title = isFirstAdhan ? 'الأذان الأول' : 'أذان الفجر';

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.midnight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppTheme.gold, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'متى تريد الاستيقاظ؟',
              style: Get.textTheme.titleLarge?.copyWith(color: AppTheme.gold),
            ),
            const SizedBox(height: 8),
            Text(
              'بالنسبة لـ $title',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Options
            _buildFajrOptionTile('قبل بـ 15 دقيقة', -15, isFirstAdhan),
            _buildFajrOptionTile('مع الأذان بالضبط', 0, isFirstAdhan),
            _buildFajrOptionTile('بعد بـ 15 دقيقة', 15, isFirstAdhan),
          ],
        ),
      ),
    );
  }

  Widget _buildFajrOptionTile(
    String label,
    int offsetMinutes,
    bool isFirstAdhan,
  ) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppTheme.gold,
        size: 16,
      ),
      onTap: () => _calculateFajrAlarm(offsetMinutes, isFirstAdhan),
    );
  }

  /// Calculate and set alarm time
  Future<void> _calculateFajrAlarm(int offsetMinutes, bool isFirstAdhan) async {
    Get.back(); // Close sheet

    final prayerService = PrayerTimesService();
    final today = await prayerService.getTodayPrayerTimes();

    if (today == null) {
      Get.snackbar('خطأ', 'تعذر الحصول على مواقيت الصلاة');
      return;
    }

    DateTime fajrTime = today.getFajrDateTime();

    // First Adhan is typically 20 mins before standard Fajr in UI logic
    if (isFirstAdhan) {
      fajrTime = fajrTime.subtract(const Duration(minutes: 20));
    }

    // Apply user offset
    final alarmTime = fajrTime.add(Duration(minutes: offsetMinutes));

    setState(() {
      _selectedHour = alarmTime.hour;
      _selectedMinute = alarmTime.minute;

      // Auto set label
      String type = isFirstAdhan ? 'الأذان الأول' : 'أذان الفجر';
      String offsetStr = '';
      if (offsetMinutes > 0) offsetStr = ' (+${offsetMinutes}د)';
      if (offsetMinutes < 0) offsetStr = ' (${offsetMinutes}د)';

      _labelController.text = 'صلاة الفجر - $type$offsetStr';
    });

    Get.snackbar(
      'تم الضبط 🕌',
      'تم تعيين الوقت: ${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
      backgroundColor: AppTheme.gold,
      colorText: AppTheme.midnight,
    );
  }
}

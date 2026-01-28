import 'package:hive/hive.dart';

part 'alarm_model.g.dart';

/// Alarm model with Hive serialization
@HiveType(typeId: 0)
class AlarmModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int hour;

  @HiveField(2)
  final int minute;

  @HiveField(3)
  final String label;

  @HiveField(4)
  final bool isEnabled;

  @HiveField(5)
  final List<int> repeatDays; // 0=Sunday, 1=Monday, ..., 6=Saturday

  @HiveField(6)
  final String soundPath;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final int snoozeCount; // Track current snooze count (0-3)

  @HiveField(9)
  final String? _vibrationPattern; // Nullable for migration

  /// Get vibration pattern with fallback
  String get vibrationPattern => _vibrationPattern ?? 'continuous';

  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.isEnabled,
    required this.repeatDays,
    required this.soundPath,
    required this.createdAt,
    this.snoozeCount = 0,
    String? vibrationPattern = 'continuous',
  }) : _vibrationPattern = vibrationPattern;

  /// Check if alarm repeats on any day
  bool get hasRepeat => repeatDays.isNotEmpty;

  /// Check if alarm is one-time only
  bool get isOneTime => repeatDays.isEmpty;

  /// Format time as HH:mm (24-hour)
  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Format time with Arabic AM/PM (ص/م)
  String get formattedTimeArabic {
    final period = hour < 12 ? 'ص' : 'م';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$displayHour:$m $period';
  }

  /// Get Arabic days abbreviation (س ن ث ر خ ج ح)
  String get repeatDaysArabic {
    if (repeatDays.isEmpty) return 'مرة واحدة';
    if (repeatDays.length == 7) return 'كل يوم';

    const daysAr = ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'];
    final selected = repeatDays.map((day) => daysAr[day]).join(' ');
    return selected;
  }

  /// Check if alarm should ring on a specific weekday
  bool shouldRingOn(int weekday) {
    if (repeatDays.isEmpty) return false;
    // DateTime weekday: Monday=1, Sunday=7
    // Our format: Sunday=0, Monday=1
    final ourWeekday = weekday == 7 ? 0 : weekday;
    return repeatDays.contains(ourWeekday);
  }

  /// Copy with modifications
  AlarmModel copyWith({
    String? id,
    int? hour,
    int? minute,
    String? label,
    bool? isEnabled,
    List<int>? repeatDays,
    String? soundPath,
    DateTime? createdAt,
    int? snoozeCount,
    String? vibrationPattern,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      soundPath: soundPath ?? this.soundPath,
      createdAt: createdAt ?? this.createdAt,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
    );
  }

  /// Reset snooze count
  AlarmModel resetSnooze() => copyWith(snoozeCount: 0);

  /// Increment snooze count (max 3)
  AlarmModel incrementSnooze() {
    if (snoozeCount >= 3) return this;
    return copyWith(snoozeCount: snoozeCount + 1);
  }

  /// Check if snooze is still available
  bool get canSnooze => snoozeCount < 3;

  /// Get snooze duration in minutes based on count
  int get snoozeDuration {
    switch (snoozeCount) {
      case 0:
        return 5; // First snooze: 5 minutes
      case 1:
        return 3; // Second snooze: 3 minutes
      case 2:
        return 1; // Third snooze: 1 minute
      default:
        return 0; // No more snooze
    }
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'isEnabled': isEnabled,
        'repeatDays': repeatDays,
        'soundPath': soundPath,
        'createdAt': createdAt.toIso8601String(),
        'snoozeCount': snoozeCount,
        'vibrationPattern': vibrationPattern,
      };

  /// Deserialize from JSON
  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
        id: json['id'],
        hour: json['hour'],
        minute: json['minute'],
        label: json['label'],
        isEnabled: json['isEnabled'],
        repeatDays: List<int>.from(json['repeatDays']),
        soundPath: json['soundPath'],
        createdAt: DateTime.parse(json['createdAt']),
        snoozeCount: json['snoozeCount'] ?? 0,
        vibrationPattern: json['vibrationPattern'] ?? 'continuous',
      );

  @override
  String toString() {
    return 'AlarmModel(id: $id, time: $formattedTime, label: $label, vib: $vibrationPattern)';
  }
}

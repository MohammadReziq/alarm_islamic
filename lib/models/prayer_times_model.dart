import 'package:hive/hive.dart';

part 'prayer_times_model.g.dart';

/// Prayer times for a single day (Hive model)
@HiveType(typeId: 2)
class PrayerTimesModel {
  @HiveField(0)
  final String date; // Format: YYYY-MM-DD

  @HiveField(1)
  final String fajr; // 04:30

  @HiveField(2)
  final String sunrise; // 05:45 (for reference)

  @HiveField(3)
  final String dhuhr; // 12:15

  @HiveField(4)
  final String asr; // 15:30

  @HiveField(5)
  final String maghrib; // 18:00

  @HiveField(6)
  final String isha; // 19:15

  PrayerTimesModel({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// Create from Aladhan API response
  factory PrayerTimesModel.fromJson(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>;
    
    return PrayerTimesModel(
      date: json['date']['gregorian']['date'], // DD-MM-YYYY
      fajr: _cleanTime(timings['Fajr']),
      sunrise: _cleanTime(timings['Sunrise']),
      dhuhr: _cleanTime(timings['Dhuhr']),
      asr: _cleanTime(timings['Asr']),
      maghrib: _cleanTime(timings['Maghrib']),
      isha: _cleanTime(timings['Isha']),
    );
  }

  /// Remove timezone from time string (05:41 (EET) -> 05:41)
  static String _cleanTime(String time) {
    return time.split(' ').first;
  }

  /// Convert to DateTime for comparison
  DateTime getFajrDateTime() => _parseDateTime(fajr);
  DateTime getDhuhrDateTime() => _parseDateTime(dhuhr);
  DateTime getAsrDateTime() => _parseDateTime(asr);
  DateTime getMaghribDateTime() => _parseDateTime(maghrib);
  DateTime getIshaDateTime() => _parseDateTime(isha);

  DateTime _parseDateTime(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  @override
  String toString() {
    return 'PrayerTimes(date: $date, Fajr: $fajr, Dhuhr: $dhuhr, Asr: $asr, Maghrib: $maghrib, Isha: $isha)';
  }
}

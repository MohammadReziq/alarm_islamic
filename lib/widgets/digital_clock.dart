import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';

/// Digital clock widget with Arabic AM/PM
class DigitalClock extends StatelessWidget {
  final int hour;
  final int minute;
  final bool showSeconds;
  final int? second;
  final double fontSize;
  final bool show24Hour;

  const DigitalClock({
    super.key,
    required this.hour,
    required this.minute,
    this.showSeconds = false,
    this.second,
    this.fontSize = 72,
    this.show24Hour = false,
  });

  @override
  Widget build(BuildContext context) {
    String displayHour;
    String period = '';

    if (show24Hour) {
      displayHour = hour.toString().padLeft(2, '0');
    } else {
      // 12-hour format with Arabic AM/PM
      final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      displayHour = h.toString();
      period = hour < 12 ? ' ص' : ' م'; // ص = AM, م = PM
    }

    final displayMinute = minute.toString().padLeft(2, '0');
    final displaySecond = showSeconds && second != null
        ? second.toString().padLeft(2, '0')
        : '';

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Hour
          Text(
            displayHour,
            style: GoogleFonts.tajawal(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.gold,
              height: 1,
            ),
          ),

          // Colon
          Padding(
            padding: EdgeInsets.symmetric(horizontal: fontSize * 0.1),
            child: Text(
              ':',
              style: GoogleFonts.tajawal(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.gold,
                height: 1,
              ),
            ),
          ),

          // Minute
          Text(
            displayMinute,
            style: GoogleFonts.tajawal(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.gold,
              height: 1,
            ),
          ),

          // Seconds (optional)
          if (showSeconds) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: fontSize * 0.1),
              child: Text(
                ':',
                style: GoogleFonts.tajawal(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gold,
                  height: 1,
                ),
              ),
            ),
            Text(
              displaySecond,
              style: GoogleFonts.tajawal(
                fontSize: fontSize * 0.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.gold,
                height: 1,
              ),
            ),
          ],

          // Period (AM/PM in Arabic)
          if (!show24Hour)
            Padding(
              padding: EdgeInsets.only(left: fontSize * 0.15, bottom: fontSize * 0.1),
              child: Text(
                period,
                style: GoogleFonts.tajawal(
                  fontSize: fontSize * 0.4,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  height: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

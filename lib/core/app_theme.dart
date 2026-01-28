import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Nashur App Theme - Islamic Luxury Dark Mode
class AppTheme {
  // Core Colors
  static const Color midnight = Color(0xFF0B1026); // Background
  static const Color gold = Color(0xFFD4AF37); // Primary/Accent
  static const Color cardBg = Color(0xFF131B3A); // Card Background
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFB8C4D9); // Silver
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF4ECDC4);

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4AF37), Color(0xFFF4D03F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF131B3A), Color(0xFF1A2347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Main Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: midnight,
      primaryColor: gold,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: gold,
        surface: cardBg,
        error: error,
        onPrimary: midnight,
        onSecondary: midnight,
        onSurface: textPrimary,
        onError: textPrimary,
      ),

      // Typography (Arabic-optimized)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.tajawal(
          fontSize: 96.sp,
          fontWeight: FontWeight.w300,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.tajawal(
          fontSize: 60.sp,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.tajawal(
          fontSize: 48.sp,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.tajawal(
          fontSize: 40.sp,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.tajawal(
          fontSize: 34.sp,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.tajawal(
          fontSize: 24.sp,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.tajawal(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.tajawal(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.tajawal(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodyLarge: GoogleFonts.tajawal(
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.tajawal(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodySmall: GoogleFonts.tajawal(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.tajawal(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: gold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: gold.withOpacity(0.1), width: 1),
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: midnight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: gold),
      ),

      // FAB Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: midnight,
        elevation: 8,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return gold;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return gold.withOpacity(0.5);
          }
          return textSecondary.withOpacity(0.3);
        }),
      ),

      // Icon Theme
      iconTheme: IconThemeData(color: gold, size: 24.sp),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: textSecondary.withOpacity(0.2),
        thickness: 1,
      ),
    );
  }

  // =============================
  // Light Theme Colors
  // =============================
  static const Color lightBg = Color(0xFFF5F5F0); // Cream background
  static const Color lightCard = Color(0xFFFFFFFF); // White cards
  static const Color lightTextPrimary = Color(0xFF1A1A1A); // Dark text
  static const Color lightTextSecondary = Color(0xFF666666); // Gray text

  /// Light Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: gold,
      colorScheme: const ColorScheme.light(
        primary: gold,
        secondary: gold,
        surface: lightCard,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onError: Colors.white,
      ),

      // Typography (same fonts, different colors)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.tajawal(
          fontSize: 96.sp,
          fontWeight: FontWeight.w300,
          color: lightTextPrimary,
        ),
        displayMedium: GoogleFonts.tajawal(
          fontSize: 60.sp,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
        ),
        displaySmall: GoogleFonts.tajawal(
          fontSize: 48.sp,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
        ),
        headlineLarge: GoogleFonts.tajawal(
          fontSize: 40.sp,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        headlineMedium: GoogleFonts.tajawal(
          fontSize: 34.sp,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        headlineSmall: GoogleFonts.tajawal(
          fontSize: 24.sp,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        titleLarge: GoogleFonts.tajawal(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleMedium: GoogleFonts.tajawal(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        titleSmall: GoogleFonts.tajawal(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: lightTextSecondary,
        ),
        bodyLarge: GoogleFonts.tajawal(
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.tajawal(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
        ),
        bodySmall: GoogleFonts.tajawal(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
        ),
        labelLarge: GoogleFonts.tajawal(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: gold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: gold.withOpacity(0.2), width: 1),
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        iconTheme: const IconThemeData(color: gold),
      ),

      // FAB Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: Colors.white,
        elevation: 8,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return gold;
          return lightTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return gold.withOpacity(0.5);
          }
          return lightTextSecondary.withOpacity(0.3);
        }),
      ),

      // Icon Theme
      iconTheme: IconThemeData(color: gold, size: 24.sp),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: lightTextSecondary.withOpacity(0.3),
        thickness: 1,
      ),
    );
  }
}

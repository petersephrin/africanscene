import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Exact Tailwind CSS Theme Variables from React:
  // --primary: 22 73% 43% -> #BF4E1B (African Terracotta)
  static const Color primaryColor = Color(0xFFBF4E1B);
  static const Color primaryDark = Color(0xFFD9652B);
  static const Color primaryLight = Color(0xFFD9652B);

  // --accent: 214 55% 28% -> #203F6F (African Navy)
  static const Color accentColor = Color(0xFF203F6F);
  static const Color accentDark = Color(0xFF3567B1);

  // --background: 30 20% 97% -> #FAF7F4 (Warm Ivory)
  static const Color bgLight = Color(0xFFFAF7F4);
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF211713);
  static const Color textMutedLight = Color(0xFF85746E);
  static const Color borderLight = Color(0xFFE6DFDB);
  static const Color mutedLight = Color(0xFFF0ECE9);
  static const Color secondaryLight = Color(0xFFF3ECE6);

  // Dark Mode Tokens
  // --background: 20 20% 8% -> #181311
  static const Color bgDark = Color(0xFF181311);
  static const Color cardDark = Color(0xFF231E1B);
  static const Color textLight = Color(0xFFF2F2F2);
  static const Color textMutedDark = Color(0xFF9B8E88);
  static const Color borderDark = Color(0xFF3E3530);
  static const Color mutedDark = Color(0xFF312A26);
  static const Color secondaryDark = Color(0xFF3B332E);

  // Status Colors
  static const Color successColor = Color(0xFF16A34A);
  static const Color warningColor = Color(0xFFD97706);
  static const Color dangerColor = Color(0xFFDC2626);

  static ThemeData lightTheme() {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryLight,
        onSecondary: primaryColor,
        tertiary: accentColor,
        onTertiary: Colors.white,
        surface: cardLight,
        onSurface: textDark,
        error: dangerColor,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: textDark,
        displayColor: textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgLight,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999), // bubble-button / btn-primary
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mutedLight, // bg-muted
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(
          color: textMutedLight,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: textMutedLight,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // rounded-xl
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerColor, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData darkTheme() {
    final baseTextTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        onPrimary: Colors.white,
        secondary: secondaryDark,
        onSecondary: Color(0xFFF7B18E),
        tertiary: accentDark,
        onTertiary: Colors.white,
        surface: cardDark,
        onSurface: textLight,
        error: dangerColor,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: textLight,
        displayColor: textLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black45,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textLight,
          side: const BorderSide(color: borderDark),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mutedDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(
          color: textMutedDark,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: textMutedDark,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerColor, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

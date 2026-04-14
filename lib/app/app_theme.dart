import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFF1A73E8);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    surface: const Color(0xFFF7F9FC),
  );

  final textTheme = GoogleFonts.notoSansTextTheme().copyWith(
    headlineMedium: GoogleFonts.notoSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF172033),
    ),
    titleLarge: GoogleFonts.notoSans(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF172033),
    ),
    titleMedium: GoogleFonts.notoSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF172033),
    ),
    bodyLarge: GoogleFonts.notoSans(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF25324B),
    ),
    bodyMedium: GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF4A5874),
    ),
    labelLarge: GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF4F7FB),
    textTheme: textTheme,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF172033),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: Colors.white,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: const Color(0xFF172033),
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: Color(0xFFE2E8F3),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD7DFEE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD7DFEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: seed, width: 1.4),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEAF1FF),
      selectedColor: const Color(0xFFD8E6FF),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: textTheme.bodyMedium!,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFD9E8FF),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? seed
              : const Color(0xFF60708C),
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => GoogleFonts.notoSans(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? seed
              : const Color(0xFF60708C),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    ),
  );
}

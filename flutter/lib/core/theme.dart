import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gamified theme: teal primary, warm accent, dark surface.
class AppTheme {
  static const Color _teal = Color(0xFF0D9488);
  static const Color _tealLight = Color(0xFF14B8A6);
  static const Color _accent = Color(0xFFF59E0B);
  static const Color _surfaceDark = Color(0xFF0F172A);
  static const Color _surfaceCard = Color(0xFF1E293B);

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: _teal,
      onPrimary: Colors.white,
      primaryContainer: _teal.withOpacity(0.3),
      onPrimaryContainer: _tealLight,
      secondary: _accent,
      onSecondary: Colors.black87,
      surface: _surfaceDark,
      onSurface: Colors.white,
      surfaceContainerHighest: _surfaceCard,
      onSurfaceVariant: Colors.white70,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _teal.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _teal, width: 2),
        ),
        labelStyle: GoogleFonts.inter(color: Colors.white70),
        hintStyle: GoogleFonts.inter(color: Colors.white54),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
      ),
    );
  }
}

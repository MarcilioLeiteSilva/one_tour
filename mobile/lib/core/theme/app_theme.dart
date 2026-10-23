import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_flavor.dart';

class AppTheme {
  static ThemeData light(FlavorConfig config) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: config.primaryColor,
      primary: config.primaryColor,
      secondary: config.secondaryColor,
      tertiary: config.accentColor,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: _buildTextTheme(colorScheme, Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: config.primaryColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: config.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData dark(FlavorConfig config) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: config.primaryColor,
      primary: config.primaryColor,
      secondary: config.secondaryColor,
      tertiary: config.accentColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF090D16),
      textTheme: _buildTextTheme(colorScheme, Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF1E293B),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: config.secondaryColor,
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: config.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme, Brightness brightness) {
    final base = brightness == Brightness.light ? ThemeData.light().textTheme : ThemeData.dark().textTheme;
    return GoogleFonts.interTextTheme(base).copyWith(
      headlineLarge: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      headlineSmall: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: colorScheme.onSurface.withValues(alpha: 0.9)),
      bodyMedium: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.75)),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
}

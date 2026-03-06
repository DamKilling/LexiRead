import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Apple/X inspired minimalist monochrome with a subtle blue accent
  static const Color _primaryColor = Color(0xFF000000); 
  static const Color _accentBlue = Color(0xFF007AFF); // Apple Blue
  
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light(useMaterial3: true);
    return baseTheme.copyWith(
      scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Pure white
      colorScheme: const ColorScheme.light(
        primary: _primaryColor,
        onPrimary: Colors.white,
        secondary: _accentBlue,
        surface: Color(0xFFF5F5F7), // Apple's light gray surface
        onSurface: Colors.black,
        primaryContainer: Color(0xFFE5E5EA), // Subtle highlight
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: -1.0),
        headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.black, letterSpacing: -0.5),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black),
        bodyLarge: GoogleFonts.inter(color: const Color(0xFF1C1C1E)),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFF3A3A3C)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.9),
        foregroundColor: Colors.black,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.black, 
          fontSize: 18, 
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFFF5F5F7), // Apple card background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Apple squircle feel
          side: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.9),
        indicatorColor: Colors.black.withOpacity(0.08),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.black, size: 26);
          }
          return const IconThemeData(color: Colors.grey, size: 24);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    return baseTheme.copyWith(
      scaffoldBackgroundColor: const Color(0xFF000000), // Pure black (X style)
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: _accentBlue,
        surface: Color(0xFF1C1C1E), // Apple dark mode surface
        onSurface: Colors.white,
        primaryContainer: Color(0xFF2C2C2E),
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.0),
        headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.inter(color: const Color(0xFFF2F2F7)),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFFAEAEB2)),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.black.withOpacity(0.9),
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white, 
          fontSize: 18, 
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.black.withOpacity(0.9),
        indicatorColor: Colors.white.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white, size: 26);
          }
          return const IconThemeData(color: Colors.grey, size: 24);
        }),
      ),
    );
  }
}
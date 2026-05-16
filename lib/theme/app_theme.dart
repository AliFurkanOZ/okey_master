import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ANA RENKLER
  static const Color backgroundDark = Color(0xFF0d0f1a);
  static const Color backgroundLight = Color(0xFF1a1a2e);
  static const Color accentCyan = Color(0xFF00f2fe);
  static const Color accentAmber = Colors.amber;
  static const Color accentMagenta = Color(0xFFfe006e);

  // ARKA PLAN GRADYANI (Tüm ekranlar için)
  static const RadialGradient mainBackgroundGradient = RadialGradient(
    colors: [backgroundLight, backgroundDark],
    radius: 1.5,
    center: Alignment.topLeft,
  );

  // GLASSMORPHISM KART DEKORASYONU
  static BoxDecoration glassDecoration({
    double borderRadius = 20.0,
    bool glow = false,
    Color glowColor = accentCyan,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      ),
      boxShadow: glow ? [
        BoxShadow(
          color: glowColor.withOpacity(0.3),
          blurRadius: 15,
          spreadRadius: 2,
        )
      ] : [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
          spreadRadius: 2,
        )
      ],
    );
  }

  // GLOBAL THEMEDATA
  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentCyan,
        brightness: Brightness.dark,
        primary: accentCyan,
        secondary: accentAmber,
      ),
      scaffoldBackgroundColor: Colors.transparent, // Gradyan arka planlar için transparent
      useMaterial3: true,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: accentCyan,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentCyan),
        titleTextStyle: TextStyle(
          color: accentCyan,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: backgroundDark,
          elevation: 5,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentCyan,
          side: const BorderSide(color: accentCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

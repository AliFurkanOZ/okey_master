import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ANA RENKLER
  static const Color backgroundDark = Color(0xFF0A0F1D); // Çok koyu lacivert
  static const Color backgroundLight = Color(0xFF121B2F); // Petrol/Gece mavisi
  static const Color accentCyan = Color(0xFF2DD4BF); // Rafine Teal/Cyan vurgu (neon olmayan)
  static const Color accentAmber = Color(0xFFFBBF24); // Yumuşak altın sarısı
  static const Color accentMagenta = Color(0xFFE879F9); // Yumuşak pembe

  // YENİ ARKA PLAN (Premium Görsel)
  static const BoxDecoration mainBackgroundDecoration = BoxDecoration(
    color: backgroundDark,
    image: DecorationImage(
      image: AssetImage('assets/images/premium_bg.png'),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken), // Hafif karartma
    ),
  );

  // GLASSMORPHISM KART DEKORASYONU
  static BoxDecoration glassDecoration({
    double borderRadius = 20.0,
    bool glow = false,
    Color glowColor = accentCyan,
  }) {
    return BoxDecoration(
      color: const Color(0xFF1E293B).withValues(alpha: 0.25), // Çok hafif saydam grafit
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 0.5, // Daha ince ve zarif bir sınır
      ),
      boxShadow: glow ? [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.15), // Parıltı daha yumuşak
          blurRadius: 15,
          spreadRadius: 1,
        )
      ] : [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 10,
          spreadRadius: 1, // Daha yumuşak gölge
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
      scaffoldBackgroundColor: Colors.transparent, // Arka plan dekorasyonu için transparent
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme().apply( // Inter, temiz ve geometrik bir font
        bodyColor: Colors.white,
        displayColor: accentCyan,
      ).copyWith(
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: -0.3),
        bodyLarge: GoogleFonts.inter(letterSpacing: -0.2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentCyan),
        titleTextStyle: TextStyle(
          color: accentCyan,
          fontWeight: FontWeight.w700, // Biraz daha rafine, çok aşırı kalın değil
          letterSpacing: 0.5, // Daraltılmış harf aralığı
          fontSize: 18, // Biraz daha minimal boyut
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan.withValues(alpha: 0.9), // Tam fosforlu olmaması için hafif saydamlık/yoğunluk
          foregroundColor: backgroundDark,
          elevation: 2, // Daha düşük gölge seviyesi
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Çok yuvarlak değil, daha rafine
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentCyan,
          side: const BorderSide(color: accentCyan, width: 1.0), // Daha ince çerçeve
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
        ),
      ),
    );
  }
}

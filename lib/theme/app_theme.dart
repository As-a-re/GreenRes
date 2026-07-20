import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global, season-agnostic design tokens: typography, radii, spacing.
/// Color is layered on top per-screen via [SeasonTheme].
class AppTheme {
  static const double radiusSm = 14;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusPill = 100;

  static TextTheme get textTheme => TextTheme(
        displaySmall: GoogleFonts.sora(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.5),
        headlineMedium: GoogleFonts.sora(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: -0.3),
        titleLarge: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium:
            GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.manrope(
            fontSize: 15, fontWeight: FontWeight.w400, height: 1.4),
        bodyMedium: GoogleFonts.manrope(
            fontSize: 13, fontWeight: FontWeight.w400, height: 1.4),
        labelLarge:
            GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
        labelSmall: GoogleFonts.manrope(
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4),
      );

  static ThemeData get base => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        textTheme: textTheme.apply(
            bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6DFFD0),
          secondary: Color(0xFFFFC24B),
          surface: Color(0xFF11161C),
        ),
        splashFactory: InkRipple.splashFactory,
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        }),
      );
}

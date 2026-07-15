import 'package:flutter/material.dart';

/// The six atmospheric moods the GreenRes UI can shift between.
/// Every screen's background, accent glow, and weather particle field
/// derive from whichever [Season] is active.
enum Season { summer, rain, spring, fall, winter, aurora }

class SeasonPalette {
  final String label;
  final String tagline;
  final List<Color> sky; // gradient stops, top -> bottom
  final Color accent; // primary glow / CTA color
  final Color accentSoft; // secondary tint for glass cards
  final Color particle; // color of falling/floating elements
  final IconData icon;

  const SeasonPalette({
    required this.label,
    required this.tagline,
    required this.sky,
    required this.accent,
    required this.accentSoft,
    required this.particle,
    required this.icon,
  });
}

class SeasonTheme {
  static const Map<Season, SeasonPalette> palettes = {
    Season.summer: SeasonPalette(
      label: 'Summer',
      tagline: 'High sun, high impact',
      sky: [Color(0xFF0F6E5B), Color(0xFF1FA37C), Color(0xFFFFC24B)],
      accent: Color(0xFFFFC24B),
      accentSoft: Color(0xFF1FA37C),
      particle: Color(0xFFFFE7A8),
      icon: Icons.wb_sunny_rounded,
    ),
    Season.rain: SeasonPalette(
      label: 'Rain',
      tagline: 'Every drop counts',
      sky: [Color(0xFF0B1F3A), Color(0xFF15406B), Color(0xFF2E6E8E)],
      accent: Color(0xFF5EC8D8),
      accentSoft: Color(0xFF2E6E8E),
      particle: Color(0xFFBFEAF2),
      icon: Icons.water_drop_rounded,
    ),
    Season.spring: SeasonPalette(
      label: 'Spring',
      tagline: 'New growth, new goals',
      sky: [Color(0xFF13342A), Color(0xFF2E8B57), Color(0xFFF7B6C2)],
      accent: Color(0xFFF7B6C2),
      accentSoft: Color(0xFF6FC28A),
      particle: Color(0xFFFFD7E0),
      icon: Icons.local_florist_rounded,
    ),
    Season.fall: SeasonPalette(
      label: 'Fall',
      tagline: 'Harvest your impact',
      sky: [Color(0xFF2B1608), Color(0xFF7A3B1E), Color(0xFFD97B3F)],
      accent: Color(0xFFE8A23A),
      accentSoft: Color(0xFFB25A2A),
      particle: Color(0xFFE8A23A),
      icon: Icons.eco_rounded,
    ),
    Season.winter: SeasonPalette(
      label: 'Winter',
      tagline: 'Resilience in the cold',
      sky: [Color(0xFF0A1628), Color(0xFF1C3A5E), Color(0xFF4A7BA6)],
      accent: Color(0xFFBFE3FF),
      accentSoft: Color(0xFF3D6E96),
      particle: Color(0xFFFFFFFF),
      icon: Icons.ac_unit_rounded,
    ),
    Season.aurora: SeasonPalette(
      label: 'Night Sky',
      tagline: 'Climate intelligence, after dark',
      sky: [Color(0xFF05070F), Color(0xFF0F1C3D), Color(0xFF1E4D4A)],
      accent: Color(0xFF6DFFD0),
      accentSoft: Color(0xFF3A6E9E),
      particle: Color(0xFF6DFFD0),
      icon: Icons.auto_awesome_rounded,
    ),
  };

  static SeasonPalette of(Season s) => palettes[s]!;

  static LinearGradient gradientFor(Season s) {
    final p = of(s);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: p.sky,
    );
  }
}

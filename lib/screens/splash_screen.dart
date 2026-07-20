import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/weather_background.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();
  final Season _season = Season.spring;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.of(context)
            .pushReplacement(_fadeRoute(const AuthGate()));
      }
    });
  }

  Route _fadeRoute(Widget page) => PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, anim, __) =>
            FadeTransition(opacity: anim, child: page),
      );

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(_season);
    return WeatherBackground(
      season: _season,
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      palette.accent.withValues(alpha: 0.9),
                      palette.accentSoft
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: palette.accent.withValues(alpha: 0.45),
                        blurRadius: 40,
                        spreadRadius: 4),
                  ],
                ),
                child: const Icon(Icons.public_rounded,
                    size: 46, color: Colors.white),
              ),
              const SizedBox(height: 22),
              const Text('GREENRES',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: Colors.white)),
              Text('E C O S Y S T E M',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 6,
                      color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(height: 8),
              Text(palette.tagline,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55))),
            ],
          ),
        ),
      ),
    );
  }
}

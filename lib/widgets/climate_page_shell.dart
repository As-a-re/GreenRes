import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import 'weather_background.dart';

class ClimatePageShell extends StatelessWidget {
  final Season season;
  final Widget child;
  final bool showBackButton;

  const ClimatePageShell({
    super.key,
    required this.season,
    required this.child,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final canGoBack = showBackButton && Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: WeatherBackground(
        season: season,
        dim: true,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              child,
              if (canGoBack)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _BackButton(season: season),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final Season season;

  const _BackButton({required this.season});

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(season);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: palette.accent, size: 16),
        ),
      ),
    );
  }
}

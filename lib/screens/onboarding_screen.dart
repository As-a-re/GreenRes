import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/weather_background.dart';
import '../widgets/glass_card.dart';
import 'main_nav.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  Season _season = Season.spring;

  final _slides = const [
    (
      title: 'Turn climate action\ninto measurable impact',
      body:
          'Log tree planting, recycling, cleanups and more. Every verified action becomes real, trackable impact.',
      icon: Icons.eco_rounded,
    ),
    (
      title: 'Earn while you\nprotect the planet',
      body:
          'GreenRes Credits convert your climate actions into airtime, data, vouchers and marketplace value.',
      icon: Icons.workspace_premium_rounded,
    ),
    (
      title: 'Stay ready for\nwhatever the sky brings',
      body:
          'Live flood, heatwave and air-quality alerts — plus an offline emergency mode when networks fail.',
      icon: Icons.shield_moon_rounded,
    ),
  ];

  final _order = [
    Season.summer,
    Season.rain,
    Season.spring,
    Season.fall,
    Season.winter,
    Season.aurora,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(_season);
    return WeatherBackground(
      season: _season,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Season / mood picker — also a fun preview of the whole visual system.
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _order.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final s = _order[i];
                  final p = SeasonTheme.of(s);
                  return GlassChip(
                    label: p.label,
                    icon: p.icon,
                    accent: p.accent,
                    selected: _season == s,
                    onTap: () => setState(() => _season = s),
                  );
                },
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              colors: [
                                palette.accent.withValues(alpha: 0.9),
                                palette.accentSoft
                              ],
                            ),
                          ),
                          child: Icon(s.icon, size: 34, color: Colors.white),
                        ),
                        const SizedBox(height: 28),
                        Text(s.title,
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: Colors.white)),
                        const SizedBox(height: 14),
                        Text(s.body,
                            style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.75))),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? palette.accent
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (_page < _slides.length - 1) {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut);
                    } else {
                      Navigator.of(context).pushReplacement(PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 500),
                        pageBuilder: (_, anim, __) => FadeTransition(
                            opacity: anim,
                            child: MainNav(initialSeason: _season)),
                      ));
                    }
                  },
                  child: Text(
                      _page < _slides.length - 1 ? 'Continue' : 'Get started',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

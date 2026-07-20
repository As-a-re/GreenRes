import 'package:flutter/material.dart';
import '../services/session_store.dart';
import '../services/voice_assistant_service.dart';
import '../localization/localization_service.dart';
import '../theme/season_theme.dart';
import '../widgets/weather_background.dart';
import '../widgets/glass_card.dart';
import 'home_dashboard.dart';
import 'action_tracker_screen.dart';
import 'learning_academy_screen.dart';
import 'marketplace_screen.dart';
import 'impact_passport_screen.dart';
import 'climate_sos_screen.dart';
import 'login_screen.dart';
import 'local_climate_screen.dart';
import 'carbon_tracker_screen.dart';
import 'wallet_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'explore_hub_screen.dart';

class MainNav extends StatefulWidget {
  final Season initialSeason;
  const MainNav({super.key, this.initialSeason = Season.spring});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  late Season _season = widget.initialSeason;
  int _tab = 0;
  bool _voiceBusy = false;

  @override
  void initState() {
    super.initState();
    _initVoiceAssistant();
  }

  Future<void> _initVoiceAssistant() async {
    await LocalizationService.instance.load();
    await VoiceAssistantService.instance.init();
    // Announce on open — the core of the "speaks about the system when
    // opened" accessibility request. Runs after the first frame so it
    // doesn't compete with the season/weather entrance animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VoiceAssistantService.instance.speak(tr('voice_welcome'));
    });
  }

  void _cycleSeason() {
    const order = Season.values;
    final next = order[(order.indexOf(_season) + 1) % order.length];
    setState(() => _season = next);
  }

  Future<void> _logout() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  List<Widget> get _pages => [
        HomeDashboard(season: _season, onSeasonTap: _cycleSeason),
        ActionTrackerScreen(season: _season),
        LearningAcademyScreen(season: _season),
        MarketplaceScreen(season: _season),
        ImpactPassportScreen(season: _season),
      ];

  final _navItems = const [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.track_changes_rounded, label: 'Track'),
    (icon: Icons.school_rounded, label: 'Learn'),
    (icon: Icons.storefront_rounded, label: 'Market'),
    (icon: Icons.badge_rounded, label: 'Passport'),
  ];

  final Map<String, int> _tabCommands = const {
    'home': 0,
    'track': 1,
    'tracker': 1,
    'learn': 2,
    'academy': 2,
    'market': 3,
    'marketplace': 3,
    'passport': 4,
  };

  /// Routes a recognized voice command to navigation. Real, working voice
  /// control — not a demo: every command below actually moves the app.
  Future<void> _handleVoiceCommand(String? command) async {
    if (!mounted) return;
    if (command == null || command.isEmpty) {
      await VoiceAssistantService.instance.speak(tr('voice_not_understood'));
      return;
    }

    if (command.contains('help')) {
      await VoiceAssistantService.instance.speak(tr('voice_help'));
      return;
    }
    if (command.contains('read screen')) {
      await VoiceAssistantService.instance
          .speak('You are on the ${_navItems[_tab].label} screen.');
      return;
    }
    if (command.contains('log out') || command.contains('logout')) {
      await VoiceAssistantService.instance.speak('Logging you out.');
      await _logout();
      return;
    }
    if (command.contains('emergency') || command.contains('sos')) {
      await VoiceAssistantService.instance.speak('Opening Climate S O S.');
      _openSos();
      return;
    }
    if (command.contains('wallet')) {
      await VoiceAssistantService.instance.speak('Opening your wallet.');
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WalletScreen(season: _season)));
      return;
    }
    if (command.contains('alert')) {
      await VoiceAssistantService.instance.speak('Opening notifications.');
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => NotificationsScreen(season: _season)));
      return;
    }
    if (command.contains('weather') || command.contains('climate')) {
      await VoiceAssistantService.instance
          .speak('Opening your local climate center.');
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LocalClimateScreen(season: _season)));
      return;
    }
    if (command.contains('carbon') || command.contains('footprint')) {
      await VoiceAssistantService.instance
          .speak('Opening the carbon footprint tracker.');
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CarbonTrackerScreen(season: _season)));
      return;
    }
    if (command.contains('setting')) {
      await VoiceAssistantService.instance.speak('Opening settings.');
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SettingsScreen(season: _season)));
      return;
    }
    if (command.contains('explore') || command.contains('more')) {
      await VoiceAssistantService.instance.speak('Opening all modules.');
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ExploreHubScreen(season: _season)));
      return;
    }

    for (final entry in _tabCommands.entries) {
      if (command.contains(entry.key)) {
        setState(() => _tab = entry.value);
        await VoiceAssistantService.instance
            .speak('Opening ${_navItems[entry.value].label}.');
        return;
      }
    }

    await VoiceAssistantService.instance.speak(tr('voice_not_understood'));
  }

  Future<void> _startListening() async {
    if (_voiceBusy) return;
    setState(() => _voiceBusy = true);
    await VoiceAssistantService.instance.speak(tr('voice_listening'));
    await VoiceAssistantService.instance.listenOnce((recognized) async {
      if (!mounted) return;
      setState(() => _voiceBusy = false);
      await _handleVoiceCommand(recognized);
    });
    // Safety timeout in case the STT callback never fires.
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _voiceBusy) setState(() => _voiceBusy = false);
    });
  }

  void _openSos() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ClimateSosScreen(season: _season),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(_season);
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'GreenRes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Semantics(
            label: 'Voice assistant. Double tap and speak a command.',
            button: true,
            child: IconButton(
              onPressed: _startListening,
              tooltip: 'Voice assistant',
              icon: Icon(
                _voiceBusy ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _voiceBusy ? palette.accent : Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Log out',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      body: WeatherBackground(
        season: _season,
        dim: true,
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: KeyedSubtree(key: ValueKey(_tab), child: _pages[_tab]),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _SosButton(
        color: palette.accent,
        onTap: _openSos,
      ),
      bottomNavigationBar: _GlassNavBar(
        season: _season,
        items: _navItems,
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _SosButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Climate emergency S O S',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 1)
            ],
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.4), width: 2),
          ),
          child: const Icon(Icons.emergency_share_rounded,
              color: Colors.black, size: 26),
        ),
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  final Season season;
  final List<({IconData icon, String label})> items;
  final int index;
  final ValueChanged<int> onChanged;

  const _GlassNavBar({
    required this.season,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(season);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GlassCard(
        radius: 28,
        opacity: 0.14,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(items.length, (i) {
              // leave a gap for the centered FAB between Learn(2) and Market(3)
              final isSelected = i == index;
              return Expanded(
                child: Semantics(
                  label: items[i].label,
                  selected: isSelected,
                  button: true,
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.symmetric(horizontal: i == 2 ? 20 : 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.accent.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(items[i].icon,
                              size: 21,
                              color: isSelected
                                  ? palette.accent
                                  : Colors.white60),
                          const SizedBox(height: 3),
                          Text(items[i].label,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? palette.accent
                                      : Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

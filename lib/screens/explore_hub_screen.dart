import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/weather_background.dart';
import '../widgets/glass_card.dart';
import 'climate_jobs_screen.dart';
import 'community_feed_screen.dart';
import 'climate_clubs_screen.dart';
import 'hero_challenges_screen.dart';
import 'floodwatch_screen.dart';
import 'climate_coach_screen.dart';
import 'tree_guardian_screen.dart';
import 'carbon_map_screen.dart';
import 'carbon_bank_screen.dart';
import 'micro_grants_screen.dart';
import 'greenlens_ar_screen.dart';
import 'agrishield_screen.dart';
import 'wallet_screen.dart';
import 'admin_dashboard_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'offline_mode_screen.dart';
import 'messages_inbox_screen.dart';
import 'local_climate_screen.dart';
import 'carbon_tracker_screen.dart';

class ExploreHubScreen extends StatelessWidget {
  final Season season;
  const ExploreHubScreen({super.key, required this.season});

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(season);

    final sections = [
      (
        title: 'Community & Growth',
        items: [
          (
            icon: Icons.dynamic_feed_rounded,
            label: 'Community Feed',
            builder: (BuildContext c) => CommunityFeedScreen(season: season)
          ),
          (
            icon: Icons.groups_2_rounded,
            label: 'Climate Clubs',
            builder: (BuildContext c) => ClimateClubsScreen(season: season)
          ),
          (
            icon: Icons.emoji_events_rounded,
            label: 'Hero Challenges',
            builder: (BuildContext c) => HeroChallengesScreen(season: season)
          ),
          (
            icon: Icons.work_rounded,
            label: 'Climate Jobs Hub',
            builder: (BuildContext c) => ClimateJobsScreen(season: season)
          ),
        ],
      ),
      (
        title: 'Intelligence & Resilience',
        items: [
          (
            icon: Icons.wb_cloudy_rounded,
            label: 'Local Climate Center',
            builder: (BuildContext c) => LocalClimateScreen(season: season)
          ),
          (
            icon: Icons.flood_rounded,
            label: 'FloodWatch Africa',
            builder: (BuildContext c) => FloodWatchScreen(season: season)
          ),
          (
            icon: Icons.public_rounded,
            label: 'Carbon Map of Africa',
            builder: (BuildContext c) => CarbonMapScreen(season: season)
          ),
          (
            icon: Icons.psychology_rounded,
            label: 'AI Climate Coach',
            builder: (BuildContext c) => ClimateCoachScreen(season: season)
          ),
          (
            icon: Icons.wifi_off_rounded,
            label: 'Offline Emergency Mode',
            builder: (BuildContext c) => OfflineModeScreen(season: season)
          ),
        ],
      ),
      (
        title: 'Green Economy',
        items: [
          (
            icon: Icons.forest_rounded,
            label: 'Tree Guardian',
            builder: (BuildContext c) => TreeGuardianScreen(season: season)
          ),
          (
            icon: Icons.account_balance_rounded,
            label: 'Community Carbon Bank',
            builder: (BuildContext c) => CarbonBankScreen(season: season)
          ),
          (
            icon: Icons.lightbulb_rounded,
            label: 'Micro-Grants',
            builder: (BuildContext c) => MicroGrantsScreen(season: season)
          ),
          (
            icon: Icons.account_balance_wallet_rounded,
            label: 'ClimateCash Wallet',
            builder: (BuildContext c) => WalletScreen(season: season)
          ),
          (
            icon: Icons.receipt_long_rounded,
            label: 'Carbon Footprint Tracker',
            builder: (BuildContext c) => CarbonTrackerScreen(season: season)
          ),
        ],
      ),
      (
        title: 'Tools',
        items: [
          (
            icon: Icons.view_in_ar_rounded,
            label: 'GreenLens AR',
            builder: (BuildContext c) => GreenLensArScreen(season: season)
          ),
          (
            icon: Icons.agriculture_rounded,
            label: 'AgriShield',
            builder: (BuildContext c) => AgriShieldScreen(season: season)
          ),
          (
            icon: Icons.chat_bubble_rounded,
            label: 'Messages',
            builder: (BuildContext c) => MessagesInboxScreen(season: season)
          ),
          (
            icon: Icons.notifications_rounded,
            label: 'Notifications',
            builder: (BuildContext c) => NotificationsScreen(season: season)
          ),
          (
            icon: Icons.settings_rounded,
            label: 'Settings',
            builder: (BuildContext c) => SettingsScreen(season: season)
          ),
        ],
      ),
      (
        title: 'Operations',
        items: [
          (
            icon: Icons.admin_panel_settings_rounded,
            label: 'Admin & Analytics',
            builder: (BuildContext c) => AdminDashboardScreen(season: season)
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WeatherBackground(
        season: season,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Row(children: [
                IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18)),
                const SizedBox(width: 4),
                const Text('Explore all modules',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 16),
              ...sections.map((section) => Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.85,
                          children: section.items.map((item) {
                            return GlassCard(
                              radius: 16,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 10),
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: item.builder)),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                        color: palette.accent
                                            .withValues(alpha: 0.16),
                                        shape: BoxShape.circle),
                                    child: Icon(item.icon,
                                        color: palette.accent, size: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(item.label,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

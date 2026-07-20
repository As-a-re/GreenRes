import 'package:flutter/material.dart';
import '../services/backend_api.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import 'notifications_screen.dart';
import 'floodwatch_screen.dart';
import 'tree_guardian_screen.dart';
import 'climate_jobs_screen.dart';
import 'carbon_bank_screen.dart';
import 'climate_clubs_screen.dart';
import 'hero_challenges_screen.dart';
import 'greenlens_ar_screen.dart';
import 'climate_coach_screen.dart';
import 'explore_hub_screen.dart';
import 'local_climate_screen.dart';

class HomeDashboard extends StatefulWidget {
  final Season season;
  final VoidCallback onSeasonTap;
  const HomeDashboard(
      {super.key, required this.season, required this.onSeasonTap});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  late Future<_DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadDashboard();
  }

  Future<_DashboardData> _loadDashboard() async {
    final results = await Future.wait([
      BackendApi.getCurrentUser().catchError((_) => <String, dynamic>{}),
      BackendApi.getListOrNull('/actions'),
      BackendApi.getListOrNull('/alerts'),
      BackendApi.getOrNull('/rewards/wallet'),
      BackendApi.getOrNull('/coach/weekly'),
    ]);

    final user = results[0] as Map<String, dynamic>?;
    final actions = results[1] as List<Map<String, dynamic>>?;
    final alerts = results[2] as List<Map<String, dynamic>>?;
    final wallet = results[3] as Map<String, dynamic>?;
    final coach = results[4] as Map<String, dynamic>?;

    return _DashboardData(
      user: user,
      actions: actions ?? const [],
      alerts: alerts ?? const [],
      wallet: wallet,
      coach: coach,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return FutureBuilder<_DashboardData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _DashboardData.empty();
        final displayName = data.user?['userMetadata']?['full_name'] ??
            data.user?['email'] ??
            'there';

        final totalCarbon = data.actions.fold<double>(
            0,
            (sum, a) =>
                sum + (double.tryParse('${a['carbon_saved_kg'] ?? 0}') ?? 0));
        final totalImpact = data.actions.fold<double>(
            0,
            (sum, a) =>
                sum + (double.tryParse('${a['impact_score'] ?? 0}') ?? 0));
        final creditsBalance = data.wallet?['credits_balance'];
        final verifiedCount =
            data.actions.where((a) => a['verified'] == true).length;

        // A simple, honest 0..1 ring value derived from verified action
        // count relative to a reasonable near-term goal (10 actions),
        // capped at 1 — not a fabricated percentile ranking.
        final ringValue = (verifiedCount / 10).clamp(0.0, 1.0);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [palette.accent, palette.accentSoft]),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12)),
                      Text(displayName.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                _WeatherToggle(
                    season: widget.season, onTap: widget.onSeasonTap),
                const SizedBox(width: 10),
                GlassCard(
                  radius: 14,
                  padding: const EdgeInsets.all(10),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          NotificationsScreen(season: widget.season))),
                  child: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Impact score hero card
            GlassCard(
              radius: 26,
              opacity: 0.13,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ImpactRing(
                    value: ringValue,
                    color: palette.accent,
                    size: 78,
                    center: Text(
                        totalImpact >= 100
                            ? totalImpact.toStringAsFixed(0)
                            : totalImpact.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Impact score',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                            '$verifiedCount verified action${verifiedCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Row(children: [
                          Icon(Icons.eco_rounded,
                              size: 15, color: palette.accent),
                          const SizedBox(width: 4),
                          Text('${totalCarbon.toStringAsFixed(1)} kg CO₂ saved total',
                              style: TextStyle(
                                  color: palette.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Stat row
            Row(
              children: [
                Expanded(
                    child: _StatTile(
                        label: 'CO₂ saved',
                        value: '${totalCarbon.toStringAsFixed(1)} kg',
                        icon: Icons.eco_rounded,
                        color: palette.accent)),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatTile(
                        label: 'GreenRes Credits',
                        value: creditsBalance == null
                            ? '—'
                            : '$creditsBalance',
                        icon: Icons.toll_rounded,
                        color: palette.accentSoft)),
              ],
            ),
            const SizedBox(height: 20),

            // AI Coach
            GlassCard(
              radius: 22,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      ClimateCoachScreen(season: widget.season))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.psychology_rounded,
                        color: palette.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Climate Coach',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          _coachSummary(data.coach),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12.5,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Live alerts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('FloodWatch Africa',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          FloodWatchScreen(season: widget.season))),
                  child: Text('View map',
                      style: TextStyle(
                          color: palette.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (data.alerts.isEmpty)
              GlassCard(
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No live alerts available right now.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12.5,
                  ),
                ),
              )
            else
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final alert = data.alerts[i];
                    final title =
                        alert['title']?.toString() ?? 'Climate update';
                    final location = alert['location_label']?.toString() ??
                        alert['message']?.toString() ??
                        '';
                    final severity =
                        (alert['severity']?.toString() ?? 'medium');
                    final visuals = _alertVisuals(severity, palette.accent);
                    return GlassCard(
                      radius: 18,
                      borderColor: visuals.$2.withValues(alpha: 0.4),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  FloodWatchScreen(season: widget.season))),
                      child: SizedBox(
                        width: 210,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(visuals.$1, color: visuals.$2, size: 16),
                              const SizedBox(width: 6),
                              Text(severity[0].toUpperCase() + severity.substring(1),
                                  style: TextStyle(
                                      color: visuals.$2,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 8),
                            Text(title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3)),
                            const Spacer(),
                            Text(location,
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.5),
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 22),

            // Quick modules
            const Text('Explore',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
              children: [
                _ModuleTile(
                    icon: Icons.park_rounded,
                    label: 'Tree\nGuardian',
                    color: palette.accent,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                TreeGuardianScreen(season: widget.season)))),
                _ModuleTile(
                    icon: Icons.work_rounded,
                    label: 'Climate\nJobs',
                    color: palette.accentSoft,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                ClimateJobsScreen(season: widget.season)))),
                _ModuleTile(
                    icon: Icons.recycling_rounded,
                    label: 'Waste2\nWealth',
                    color: palette.accent,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                CarbonBankScreen(season: widget.season)))),
                _ModuleTile(
                    icon: Icons.groups_2_rounded,
                    label: 'Climate\nClubs',
                    color: palette.accentSoft,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                ClimateClubsScreen(season: widget.season)))),
                _ModuleTile(
                    icon: Icons.emoji_events_rounded,
                    label: 'Hero\nChallenges',
                    color: palette.accent,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => HeroChallengesScreen(
                                season: widget.season)))),
                _ModuleTile(
                    icon: Icons.view_in_ar_rounded,
                    label: 'GreenLens\nAR',
                    color: palette.accentSoft,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                GreenLensArScreen(season: widget.season)))),
                _ModuleTile(
                    icon: Icons.wb_cloudy_rounded,
                    label: 'Local\nClimate',
                    color: palette.accent,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                LocalClimateScreen(season: widget.season)))),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              radius: 18,
              opacity: 0.12,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ExploreHubScreen(season: widget.season))),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.16),
                        shape: BoxShape.circle),
                    child: Icon(Icons.explore_rounded,
                        color: palette.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Browse all modules',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Open jobs, feed, grants, admin, tools and more',
                            style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11.5,
                                height: 1.3)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: palette.accent, size: 22),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _coachSummary(Map<String, dynamic>? coach) {
    if (coach == null) {
      return 'Log your first verified action to get personalized coaching here.';
    }
    final carbon7d =
        double.tryParse('${coach['carbon_saved_7d'] ?? 0}') ?? 0;
    final actions7d = coach['actions_7d'] ?? 0;
    final goal = coach['recommended_goal'] ?? 3;
    final next = coach['next_challenge']?.toString() ??
        'No active challenge right now';
    if (actions7d == 0) {
      return 'No verified actions logged this week yet. Aim for $goal this week — next up: "$next".';
    }
    return 'You logged $actions7d action${actions7d == 1 ? '' : 's'} and prevented ${carbon7d.toStringAsFixed(1)} kg CO₂ this week. Next up: "$next".';
  }

  (IconData, Color) _alertVisuals(String severity, Color fallback) {
    switch (severity) {
      case 'critical':
      case 'high':
        return (Icons.warning_rounded, const Color(0xFFE85C5C));
      case 'medium':
        return (Icons.info_rounded, const Color(0xFFFFC24B));
      default:
        return (Icons.info_outline_rounded, fallback);
    }
  }
}

class _DashboardData {
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>> actions;
  final List<Map<String, dynamic>> alerts;
  final Map<String, dynamic>? wallet;
  final Map<String, dynamic>? coach;

  const _DashboardData({
    required this.user,
    required this.actions,
    required this.alerts,
    required this.wallet,
    required this.coach,
  });

  const _DashboardData.empty()
      : user = null,
        actions = const [],
        alerts = const [],
        wallet = null,
        coach = null;
}

class _WeatherToggle extends StatelessWidget {
  final Season season;
  final VoidCallback onTap;
  const _WeatherToggle({required this.season, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(season);
    return GlassCard(
      radius: 14,
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Icon(palette.icon, color: palette.accent, size: 20),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ModuleTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2)),
        ],
      ),
    );
  }
}

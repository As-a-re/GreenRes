import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';

class ClimateCoachScreen extends StatefulWidget {
  final Season season;
  const ClimateCoachScreen({super.key, required this.season});

  @override
  State<ClimateCoachScreen> createState() => _ClimateCoachScreenState();
}

class _ClimateCoachScreenState extends State<ClimateCoachScreen> {
  late Future<_CoachData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_CoachData> _load() async {
    final results = await Future.wait([
      BackendApi.getOrNull('/coach/weekly'),
      BackendApi.getListOrNull('/actions'),
    ]);
    final coach = results[0] as Map<String, dynamic>?;
    final actions = (results[1] as List<Map<String, dynamic>>?) ?? const [];

    // Bucket each of the last 7 days' verified carbon savings for the chart.
    final now = DateTime.now();
    final daily = List<double>.filled(7, 0);
    for (final action in actions) {
      final createdAt = DateTime.tryParse(action['created_at']?.toString() ?? '');
      if (createdAt == null) continue;
      final daysAgo = now.difference(createdAt).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        final carbon = double.tryParse('${action['carbon_saved_kg'] ?? 0}') ?? 0;
        daily[6 - daysAgo] += carbon;
      }
    }

    return _CoachData(coach: coach, dailyCarbon: daily);
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    final days = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return labels[date.weekday - 1];
    });

    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('AI Climate Coach',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Your weekly impact report',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 18),
          FutureBuilder<_CoachData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              final data = snapshot.data ??
                  const _CoachData(coach: null, dailyCarbon: [0, 0, 0, 0, 0, 0, 0]);
              final carbon7d =
                  double.tryParse('${data.coach?['carbon_saved_7d'] ?? 0}') ?? 0;
              final actions7d = data.coach?['actions_7d'] ?? 0;
              final goal = data.coach?['recommended_goal'] ?? 3;
              final nextChallenge =
                  data.coach?['next_challenge']?.toString() ??
                      'No active challenge right now';
              final maxDaily = data.dailyCarbon.isEmpty
                  ? 1.0
                  : data.dailyCarbon.reduce((a, b) => a > b ? a : b);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    radius: 24,
                    opacity: 0.14,
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
                          child: Text(
                            actions7d == 0
                                ? 'No verified actions logged this week yet. Aim for $goal — every action counts.'
                                : 'You logged $actions7d action${actions7d == 1 ? '' : 's'} and prevented ${carbon7d.toStringAsFixed(1)} kg CO₂ this week.',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12.5,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('This week\'s activity',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  GlassCard(
                    radius: 22,
                    child: SizedBox(
                      height: 140,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (i) {
                          final ratio = maxDaily > 0
                              ? data.dailyCarbon[i] / maxDaily
                              : 0.0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    height: 90 * ratio.clamp(0.03, 1.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          palette.accentSoft,
                                          palette.accent
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(days[i],
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _CoachStat(
                              label: 'Recommended goal',
                              value: '$goal actions/wk',
                              icon: Icons.flag_rounded,
                              color: palette.accent)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _CoachStat(
                              label: 'Next challenge',
                              value: nextChallenge,
                              icon: Icons.emoji_events_rounded,
                              color: palette.accentSoft)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CoachData {
  final Map<String, dynamic>? coach;
  final List<double> dailyCarbon;
  const _CoachData({required this.coach, required this.dailyCarbon});
}

class _CoachStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _CoachStat(
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55), fontSize: 11)),
        ],
      ),
    );
  }
}

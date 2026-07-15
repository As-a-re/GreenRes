import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';

class CarbonMapScreen extends StatefulWidget {
  final Season season;
  const CarbonMapScreen({super.key, required this.season});

  @override
  State<CarbonMapScreen> createState() => _CarbonMapScreenState();
}

class _CarbonMapScreenState extends State<CarbonMapScreen> {
  late Future<Map<String, dynamic>?> _impactFuture;

  @override
  void initState() {
    super.initState();
    _impactFuture = BackendApi.getOrNull('/impact');
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Carbon Map of Africa',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Continental impact, aggregated across every user',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 1.05,
            child: GlassCard(
              radius: 26,
              opacity: 0.1,
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.1,
                            colors: [
                              palette.accent.withValues(alpha: 0.22),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(Icons.public_rounded,
                          size: 46, color: Colors.white.withValues(alpha: 0.15)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'A live geospatial heatmap needs a mapping SDK (e.g. Mapbox or Google Maps) wired to per-region data — the totals below are real, this visual is a placeholder for that integration.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 10.5, height: 1.4),
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<Map<String, dynamic>?>(
            future: _impactFuture,
            builder: (context, snapshot) {
              final impact = snapshot.data ?? const {};
              final treesPlanted = impact['trees_planted'] ?? 0;
              final carbonSaved = impact['carbon_saved_kg'];
              final recyclingActions = impact['recycling_actions'] ?? 0;
              final verifiedActions = impact['verified_actions'] ?? 0;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              label: 'Trees planted',
                              value: '$treesPlanted',
                              icon: Icons.park_rounded,
                              color: palette.accent)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              label: 'CO₂ saved',
                              value: carbonSaved == null
                                  ? '—'
                                  : '${(double.tryParse('$carbonSaved') ?? 0).toStringAsFixed(0)} kg',
                              icon: Icons.eco_rounded,
                              color: palette.accentSoft)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              label: 'Recycling actions',
                              value: '$recyclingActions',
                              icon: Icons.recycling_rounded,
                              color: palette.accent)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              label: 'Verified actions',
                              value: '$verifiedActions',
                              icon: Icons.verified_rounded,
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

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
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

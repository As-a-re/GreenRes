import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';

class CarbonBankScreen extends StatefulWidget {
  final Season season;
  const CarbonBankScreen({super.key, required this.season});

  @override
  State<CarbonBankScreen> createState() => _CarbonBankScreenState();
}

class _CarbonBankScreenState extends State<CarbonBankScreen> {
  late Future<List<Map<String, dynamic>>?> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = BackendApi.getListOrNull('/carbon-bank');
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Community Carbon Bank',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Community-funded projects, backed by credits',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>?>(
            future: _projectsFuture,
            builder: (context, snapshot) {
              final projects = snapshot.data ?? const [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                );
              }
              if (projects.isEmpty) {
                return GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No community projects yet. Submit one from the Micro-Grants Platform.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                );
              }
              return Column(
                children: projects.map((p) {
                  final goal = (p['goal_amount'] as num?)?.toDouble() ?? 0;
                  final raised = (p['raised_amount'] as num?)?.toDouble() ?? 0;
                  final progress = goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassCard(
                      radius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['title']?.toString() ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5)),
                          const SizedBox(height: 3),
                          Text(p['description']?.toString() ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11.5)),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation(palette.accent),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                              '${(progress * 100).toInt()}% funded · ${p['votes'] ?? 0} votes',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 10.5)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';

class ClimateJobsScreen extends StatelessWidget {
  final Season season;
  const ClimateJobsScreen({super.key, required this.season});

  Future<List<Map<String, dynamic>>> _loadJobs() => BackendApi.getList('/jobs');

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(season);
    final types = [
      'All',
      'Full-time',
      'Internship',
      'Fellowship',
      'Scholarship'
    ];
    return ClimatePageShell(
      season: season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Climate Jobs & Opportunities',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Matched to your skills and learning history',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GlassChip(
                  label: types[i], accent: palette.accent, selected: i == 0),
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadJobs(),
            builder: (context, snapshot) {
              final jobs = snapshot.data ?? const [];
              if (jobs.isEmpty) {
                return GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No climate jobs available right now. New opportunities will appear here soon.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                );
              }
              return Column(
                children: jobs
                    .map((j) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            radius: 22,
                            onTap: () => showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF11161C),
                                title: Text(j['title']?.toString() ?? 'Opportunity',
                                    style: const TextStyle(color: Colors.white)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${j['organization'] ?? ''} · ${j['job_type'] ?? ''}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                                    const SizedBox(height: 8),
                                    Text(j['location']?.toString() ?? '',
                                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    if (j['description'] != null) ...[
                                      const SizedBox(height: 12),
                                      Text(j['description'].toString(),
                                          style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4)),
                                    ],
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: palette.accent
                                              .withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      child: Icon(Icons.work_rounded,
                                          color: palette.accent, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(j['title']?.toString() ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14)),
                                          const SizedBox(height: 3),
                                          Text(
                                              j['organization']?.toString() ??
                                                  '',
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.55),
                                                  fontSize: 11.5)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                          color: palette.accent
                                              .withValues(alpha: 0.18),
                                          borderRadius:
                                              BorderRadius.circular(100)),
                                      child: Text(
                                          '${(j['match_score'] as num?)?.round() ?? 0}% match',
                                          style: TextStyle(
                                              color: palette.accent,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _Tag(
                                        icon: Icons.work_outline_rounded,
                                        label: j['job_type']?.toString() ?? ''),
                                    const SizedBox(width: 10),
                                    _Tag(
                                        icon: Icons.place_outlined,
                                        label: j['location']?.toString() ?? ''),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Tag({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11)),
      ],
    );
  }
}

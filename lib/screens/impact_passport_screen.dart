import 'package:flutter/material.dart';
import '../services/backend_api.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';

class ImpactPassportScreen extends StatefulWidget {
  final Season season;
  const ImpactPassportScreen({super.key, required this.season});

  @override
  State<ImpactPassportScreen> createState() => _ImpactPassportScreenState();
}

class _ImpactPassportScreenState extends State<ImpactPassportScreen> {
  late Future<_PassportData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_PassportData> _load() async {
    final results = await Future.wait([
      BackendApi.getOrNull('/profiles/me'),
      BackendApi.getListOrNull('/trees'),
      BackendApi.getListOrNull('/actions'),
      BackendApi.getListOrNull('/learning/progress'),
      BackendApi.getListOrNull('/learning/courses'),
    ]);

    final profile = results[0] as Map<String, dynamic>?;
    final trees = (results[1] as List<Map<String, dynamic>>?) ?? const [];
    final actions = (results[2] as List<Map<String, dynamic>>?) ?? const [];
    final progress = (results[3] as List<Map<String, dynamic>>?) ?? const [];
    final courses = (results[4] as List<Map<String, dynamic>>?) ?? const [];

    final completedCourseIds = progress
        .where((p) => p['completed'] == true)
        .map((p) => p['course_id']?.toString())
        .whereType<String>()
        .toSet();
    final completedCourses = courses
        .where((c) => completedCourseIds.contains(c['id']?.toString()))
        .toList();

    final totalCarbon = actions.fold<double>(
        0, (sum, a) => sum + (double.tryParse('${a['carbon_saved_kg'] ?? 0}') ?? 0));
    final verifiedCount = actions.where((a) => a['verified'] == true).length;

    return _PassportData(
      displayName: profile?['display_name']?.toString(),
      location: profile?['location']?.toString(),
      memberSince: profile?['created_at']?.toString(),
      treesPlanted: trees.length,
      verifiedActions: verifiedCount,
      totalCarbonKg: totalCarbon,
      completedCourses: completedCourses,
    );
  }

  String _formatMemberSince(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Member since ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Climate Impact Passport',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Your verified climate identity',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 20),
          FutureBuilder<_PassportData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              final data = snapshot.data;
              final displayName = data?.displayName ?? 'GreenRes User';
              final memberSince = data == null
                  ? ''
                  : _formatMemberSince(data.memberSince);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    radius: 26,
                    opacity: 0.14,
                    borderColor: palette.accent.withValues(alpha: 0.35),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [
                                  palette.accent,
                                  palette.accentSoft
                                ]),
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16)),
                                  if (data?.location != null)
                                    Text(
                                        '${data!.location} · $memberSince',
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11.5))
                                  else if (memberSince.isNotEmpty)
                                    Text(memberSince,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11.5)),
                                ],
                              ),
                            ),
                            Icon(Icons.qr_code_rounded,
                                color: Colors.white.withValues(alpha: 0.6)),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            _PassportStat(
                                label: 'Trees planted',
                                value: '${data?.treesPlanted ?? 0}'),
                            _PassportStat(
                                label: 'Verified actions',
                                value: '${data?.verifiedActions ?? 0}'),
                            _PassportStat(
                                label: 'CO₂ saved',
                                value:
                                    '${(data?.totalCarbonKg ?? 0).toStringAsFixed(1)} kg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('Certifications',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (data == null || data.completedCourses.isEmpty)
                    GlassCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No certifications yet. Complete a course in the Learning Academy to earn one.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: data.completedCourses.map((course) {
                        return SizedBox(
                          width:
                              (MediaQuery.of(context).size.width - 52) / 2,
                          child: _CertChip(
                              label: course['title']?.toString() ?? 'Course',
                              color: palette.accent),
                        );
                      }).toList(),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Text(
              'Use your Impact Passport for scholarships, jobs, and fellowship applications.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11.5,
                  height: 1.4)),
        ],
      ),
    );
  }
}

class _PassportData {
  final String? displayName;
  final String? location;
  final String? memberSince;
  final int treesPlanted;
  final int verifiedActions;
  final double totalCarbonKg;
  final List<Map<String, dynamic>> completedCourses;

  const _PassportData({
    required this.displayName,
    required this.location,
    required this.memberSince,
    required this.treesPlanted,
    required this.verifiedActions,
    required this.totalCarbonKg,
    required this.completedCourses,
  });
}

class _PassportStat extends StatelessWidget {
  final String label, value;
  const _PassportStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _CertChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CertChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_rounded, color: color, size: 22),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.3)),
        ],
      ),
    );
  }
}

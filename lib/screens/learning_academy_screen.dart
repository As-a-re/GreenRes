import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';

class LearningAcademyScreen extends StatefulWidget {
  final Season season;
  const LearningAcademyScreen({super.key, required this.season});

  @override
  State<LearningAcademyScreen> createState() => _LearningAcademyScreenState();
}

class _LearningAcademyScreenState extends State<LearningAcademyScreen> {
  late Future<_LearningData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_LearningData> _load() async {
    final results = await Future.wait([
      BackendApi.getListOrNull('/learning/courses'),
      BackendApi.getListOrNull('/learning/progress'),
      BackendApi.getOrNull('/rewards/wallet'),
    ]);
    final courses = (results[0] as List<Map<String, dynamic>>?) ?? const [];
    final progress = (results[1] as List<Map<String, dynamic>>?) ?? const [];
    final wallet = results[2] as Map<String, dynamic>?;

    final progressByCourse = {
      for (final p in progress) p['course_id']?.toString(): p,
    };

    return _LearningData(
        courses: courses, progressByCourse: progressByCourse, wallet: wallet);
  }

  Future<void> _advance(String courseId, double currentPercent) async {
    final next = (currentPercent + 25).clamp(0, 100).toDouble();
    await BackendApi.postOrNull('/learning/progress', body: {
      'courseId': courseId,
      'progressPercent': next,
      'completed': next >= 100,
    });
    setState(() => _dataFuture = _load());
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      children: [
        const Text('Climate Learning Academy',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Micro-courses that build your Impact Passport',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        const SizedBox(height: 18),
        FutureBuilder<_LearningData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            final data = snapshot.data ??
                const _LearningData(
                    courses: [], progressByCourse: {}, wallet: null);
            final completedCount = data.progressByCourse.values
                .where((p) => p['completed'] == true)
                .length;
            final tier = data.wallet?['tier_name']?.toString() ?? 'starter';
            final lifetimeCredits = data.wallet?['lifetime_credits'] ?? 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        radius: 20,
                        child: Row(
                          children: [
                            const Text('🎓', style: TextStyle(fontSize: 26)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$completedCount completed',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                  const Text('Courses finished',
                                      style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassCard(
                        radius: 20,
                        child: Row(
                          children: [
                            Icon(Icons.bolt_rounded,
                                color: palette.accent, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$lifetimeCredits credits',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                  Text(
                                      '${tier[0].toUpperCase()}${tier.substring(1)} tier',
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text('Courses',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (data.courses.isEmpty)
                  GlassCard(
                    radius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No learning content available yet. Courses will appear here once they are published.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  )
                else
                  ...data.courses.map((course) {
                    final courseId = course['id']?.toString() ?? '';
                    final p = data.progressByCourse[courseId];
                    final percent =
                        (p?['progress_percent'] as num?)?.toDouble() ?? 0;
                    final completed = p?['completed'] == true;
                    final minutes = course['duration_minutes'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        radius: 20,
                        onTap: completed || courseId.isEmpty
                            ? null
                            : () => _advance(courseId, percent),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: palette.accentSoft
                                      .withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(14)),
                              child: Icon(
                                  completed
                                      ? Icons.check_circle_rounded
                                      : Icons.school_rounded,
                                  color: Colors.white,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course['title']?.toString() ?? '',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5)),
                                  const SizedBox(height: 3),
                                  Text(
                                      '${course['category']?.toString() ?? ''} · $minutes min · ${course['xp_reward'] ?? 0} XP',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          fontSize: 11.5)),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: percent / 100,
                                      minHeight: 5,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.1),
                                      valueColor: AlwaysStoppedAnimation(
                                          palette.accent),
                                    ),
                                  ),
                                  if (!completed) ...[
                                    const SizedBox(height: 4),
                                    Text('Tap to continue · ${percent.toInt()}%',
                                        style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.4),
                                            fontSize: 10)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
            'Certificates unlock your Climate Impact Passport and Jobs Hub recommendations.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11.5,
                height: 1.4)),
      ],
    );
  }
}

class _LearningData {
  final List<Map<String, dynamic>> courses;
  final Map<String?, Map<String, dynamic>> progressByCourse;
  final Map<String, dynamic>? wallet;
  const _LearningData({
    required this.courses,
    required this.progressByCourse,
    required this.wallet,
  });
}

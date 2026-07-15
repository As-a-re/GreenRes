import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';
import 'verification_upload_screen.dart';

class HeroChallengesScreen extends StatefulWidget {
  final Season season;
  const HeroChallengesScreen({super.key, required this.season});

  @override
  State<HeroChallengesScreen> createState() => _HeroChallengesScreenState();
}

class _HeroChallengesScreenState extends State<HeroChallengesScreen> {
  late Future<List<Map<String, dynamic>>?> _challengesFuture;

  @override
  void initState() {
    super.initState();
    _challengesFuture = BackendApi.getListOrNull('/challenges');
  }

  Future<void> _join(String challengeId) async {
    await BackendApi.postOrNull('/challenges/$challengeId/join');
    if (!mounted) return;
    setState(() {
      _challengesFuture = BackendApi.getListOrNull('/challenges');
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Climate Hero Challenges',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Short, viral, rewarding — upload proof, earn credits',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 18),
          FutureBuilder<List<Map<String, dynamic>>?>(
            future: _challengesFuture,
            builder: (context, snapshot) {
              final challenges = snapshot.data ?? const [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                );
              }
              if (challenges.isEmpty) {
                return GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No challenges are running right now. Check back soon, or start one from your Climate Club.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                );
              }

              final featured = challenges.first;
              final rest = challenges.skip(1).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    radius: 24,
                    opacity: 0.16,
                    borderColor: palette.accent.withValues(alpha: 0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.local_fire_department_rounded,
                              color: palette.accent),
                          const SizedBox(width: 8),
                          Text('Featured',
                              style: TextStyle(
                                  color: palette.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ]),
                        const SizedBox(height: 10),
                        Text(featured['title']?.toString() ?? 'Challenge',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                            '${featured['participant_count'] ?? 0} people joined · '
                            '${featured['days_left'] ?? 0} days left · '
                            '${featured['reward_credits'] ?? 0} credits',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12)),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.accent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final id = featured['id']?.toString();
                              if (id != null) await _join(id);
                              if (!context.mounted) return;
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => VerificationUploadScreen(
                                      season: widget.season)));
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Join challenge',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rest.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('More challenges',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...rest.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            radius: 20,
                            onTap: () async {
                              final id = c['id']?.toString();
                              if (id != null) await _join(id);
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(c['title']?.toString() ?? '',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13.5)),
                                      const SizedBox(height: 4),
                                      Text(
                                          '${c['participant_count'] ?? 0} joined · ${c['days_left'] ?? 0}d left',
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.5),
                                              fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                                Text('${c['reward_credits'] ?? 0} cr',
                                    style: TextStyle(
                                        color: palette.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5)),
                              ],
                            ),
                          ),
                        )),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

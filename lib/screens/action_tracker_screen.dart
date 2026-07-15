import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import 'verification_upload_screen.dart';
import '../services/backend_api.dart';

class ActionTrackerScreen extends StatelessWidget {
  final Season season;
  const ActionTrackerScreen({super.key, required this.season});

  Future<List<Map<String, dynamic>>?> _loadActions() =>
      BackendApi.getListOrNull('/actions');

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(season);
    final categories = [
      'Tree planting',
      'Recycling',
      'Composting',
      'Transport',
      'Cleanups',
      'Water',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      children: [
        const Text('Action Tracker',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Log a verified climate action',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        const SizedBox(height: 18),

        // Log new action CTA
        GlassCard(
          radius: 22,
          opacity: 0.13,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VerificationUploadScreen(season: season))),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [palette.accent, palette.accentSoft]),
                ),
                child:
                    const Icon(Icons.add_a_photo_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Log a new action',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 3),
                    Text('Photo + GPS + timestamp = instant AI verification',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.5)),
            ],
          ),
        ),
        const SizedBox(height: 18),

        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => GlassChip(
              label: categories[i],
              accent: palette.accent,
              selected: i == 0,
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text('Recent activity',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        FutureBuilder<List<Map<String, dynamic>>?>(
          future: _loadActions(),
          builder: (context, snapshot) {
            final actions = snapshot.data ?? const [];
            if (actions.isEmpty) {
              return GlassCard(
                radius: 20,
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No climate actions yet. Log your first verified action to populate this feed.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              );
            }
            return Column(
              children: actions
                  .map((action) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          radius: 20,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color:
                                        palette.accent.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(14)),
                                child: Icon(Icons.eco_rounded,
                                    color: palette.accent, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(action['title']?.toString() ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.5)),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.verified_rounded,
                                            size: 13, color: palette.accent),
                                        const SizedBox(width: 4),
                                        Text('Live verified',
                                            style: TextStyle(
                                                color: palette.accent,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 8),
                                        Text(
                                            '· ${action['created_at']?.toString() ?? ''}',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.4),
                                                fontSize: 11.5)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text('Verified',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import 'community_feed_screen.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';

class ClimateClubsScreen extends StatefulWidget {
  final Season season;
  const ClimateClubsScreen({super.key, required this.season});

  @override
  State<ClimateClubsScreen> createState() => _ClimateClubsScreenState();
}

class _ClimateClubsScreenState extends State<ClimateClubsScreen> {
  late Future<List<Map<String, dynamic>>> _clubsFuture;
  final Set<String> _joining = {};

  @override
  void initState() {
    super.initState();
    _clubsFuture = BackendApi.getList('/clubs');
  }

  Future<void> _join(String clubId) async {
    setState(() => _joining.add(clubId));
    final result = await BackendApi.postOrNull('/clubs/$clubId/join');
    if (!mounted) return;
    setState(() => _joining.remove(clubId));
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You joined the club!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    final categories = ['All', 'School', 'University', 'Community'];
    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Climate Clubs',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Join, organize, and track impact together',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GlassChip(
                  label: categories[i],
                  accent: palette.accent,
                  selected: i == 0),
            ),
          ),
          const SizedBox(height: 18),
          GlassCard(
            radius: 20,
            borderColor: palette.accent.withValues(alpha: 0.4),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CommunityFeedScreen(season: widget.season))),
            child: Row(
              children: [
                Icon(Icons.add_circle_rounded, color: palette.accent, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('Start a new climate club',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5))),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _clubsFuture,
            builder: (context, snapshot) {
              final clubs = snapshot.data ?? const [];
              if (clubs.isEmpty) {
                return GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No climate clubs available yet. Create one to start your local community.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                );
              }
              return Column(
                children: clubs.map((c) {
                  final id = c['id']?.toString() ?? '';
                  final busy = _joining.contains(id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      radius: 20,
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(colors: [
                                palette.accent,
                                palette.accentSoft
                              ]),
                            ),
                            child: const Icon(Icons.groups_rounded,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['name']?.toString() ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5)),
                                const SizedBox(height: 4),
                                Text(
                                    '${c['category']?.toString() ?? ''} · ${c['members_count']?.toString() ?? '0'} members',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.5),
                                        fontSize: 11.5)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: busy || id.isEmpty ? null : () => _join(id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                  color: palette.accent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(100)),
                              child: busy
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: palette.accent),
                                    )
                                  : Text('Join',
                                      style: TextStyle(
                                          color: palette.accent,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
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

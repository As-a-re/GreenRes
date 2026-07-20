import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';

class CommunityFeedScreen extends StatefulWidget {
  final Season season;
  const CommunityFeedScreen({super.key, required this.season});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  late Future<List<Map<String, dynamic>>> _feedFuture;

  @override
  void initState() {
    super.initState();
    _feedFuture = BackendApi.getList('/community/feed');
  }

  Future<void> _compose() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11161C),
        title: const Text('Share an update',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. planted 5 mangrove trees',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Post'),
          ),
        ],
      ),
    );

    if (result != true || controller.text.trim().isEmpty) return;
    await BackendApi.postOrNull('/community/feed', body: {
      'action': controller.text.trim(),
    });
    setState(() {
      _feedFuture = BackendApi.getList('/community/feed');
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Community',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              GlassCard(
                  radius: 14,
                  padding: const EdgeInsets.all(10),
                  onTap: _compose,
                  child: const Icon(Icons.edit_note_rounded,
                      color: Colors.white, size: 20)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Impact stories from your climate network',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 18),
          GlassCard(
            radius: 20,
            onTap: _compose,
            child: Row(
              children: [
                CircleAvatar(
                    radius: 18,
                    backgroundColor: palette.accent.withValues(alpha: 0.3),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Share your latest climate action…',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13))),
                Icon(Icons.photo_camera_outlined,
                    color: palette.accent, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _feedFuture,
            builder: (context, snapshot) {
              final feed = snapshot.data ?? const [];
              if (feed.isEmpty) {
                return GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No community activity yet. Your first post will appear here.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                );
              }
              return Column(
                children: feed.map((post) {
                  final likes = post['likes_count']?.toString() ?? '0';
                  final comments = post['comments_count']?.toString() ?? '0';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassCard(
                      radius: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color:
                                        palette.accent.withValues(alpha: 0.18),
                                    shape: BoxShape.circle),
                                child: Icon(Icons.public_rounded,
                                    color: palette.accent, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post['display_name']?.toString() ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                    Text(post['created_at']?.toString() ?? '',
                                        style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.45),
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              Icon(Icons.more_horiz_rounded,
                                  color: Colors.white.withValues(alpha: 0.4)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                              '${post['display_name']?.toString() ?? ''} ${post['action']?.toString() ?? ''}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  height: 1.4)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _FeedAction(
                                  icon: Icons.eco_rounded,
                                  label: likes,
                                  color: palette.accent),
                              const SizedBox(width: 18),
                              _FeedAction(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  label: comments,
                                  color: Colors.white70),
                              const SizedBox(width: 18),
                              const _FeedAction(
                                  icon: Icons.share_outlined,
                                  label: 'Share',
                                  color: Colors.white70),
                            ],
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

class _FeedAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeedAction(
      {required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

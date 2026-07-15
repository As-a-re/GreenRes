import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';
import 'messaging_screen.dart';

class MessagesInboxScreen extends StatefulWidget {
  final Season season;
  const MessagesInboxScreen({super.key, required this.season});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  late Future<List<Map<String, dynamic>>?> _threadsFuture;

  @override
  void initState() {
    super.initState();
    _threadsFuture = BackendApi.getListOrNull('/messages/threads');
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '${days}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Messages',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Your marketplace conversations',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 18),
          FutureBuilder<List<Map<String, dynamic>>?>(
            future: _threadsFuture,
            builder: (context, snapshot) {
              final threads = snapshot.data ?? const [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                );
              }
              if (threads.isEmpty) {
                return GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No conversations yet. Message a seller from a marketplace listing to start one.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                );
              }
              return Column(
                children: threads.map((thread) {
                  final otherName =
                      thread['other_user_name']?.toString() ?? 'GreenRes user';
                  final listingTitle = thread['listing_title']?.toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      radius: 18,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => MessagingScreen(
                              season: widget.season,
                              threadId: thread['id']?.toString() ?? '',
                              otherUserName: otherName))),
                      child: Row(
                        children: [
                          CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  palette.accent.withValues(alpha: 0.25),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(otherName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                if (listingTitle != null)
                                  Text('Re: $listingTitle',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(_formatDate(thread['updated_at']?.toString()),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
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

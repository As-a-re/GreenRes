import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/weather_background.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';

class MessagingScreen extends StatefulWidget {
  final Season season;
  final String threadId;
  final String otherUserName;
  const MessagingScreen({
    super.key,
    required this.season,
    required this.threadId,
    required this.otherUserName,
  });

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  late Future<List<Map<String, dynamic>>> _messagesFuture;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _messagesFuture = BackendApi.getList('/messages/threads/${widget.threadId}');
    BackendApi.getCurrentUser().then((user) {
      if (mounted) setState(() => _currentUserId = user['id']?.toString());
    }).catchError((_) {});
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.threadId.isEmpty) return;
    setState(() => _sending = true);
    try {
      await BackendApi.post('/messages/threads/send', body: {
        'threadId': widget.threadId,
        'body': text,
      });
      _controller.clear();
      if (!mounted) return;
      setState(() {
        _messagesFuture =
            BackendApi.getList('/messages/threads/${widget.threadId}');
        _sending = false;
      });
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WeatherBackground(
        season: widget.season,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18)),
                    CircleAvatar(
                        radius: 17,
                        backgroundColor: palette.accent.withValues(alpha: 0.3),
                        child: const Icon(Icons.storefront_rounded,
                            color: Colors.white, size: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.otherUserName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _messagesFuture,
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? const [];
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No messages yet. Say hello!',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13),
                          ),
                        ),
                      );
                    }
                    return ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      children: messages
                          .map((m) => _Bubble(
                                text: m['body']?.toString() ?? '',
                                mine: m['sender_id']?.toString() ==
                                    _currentUserId,
                                time: _formatTime(m['created_at']?.toString()),
                                accent: palette.accent,
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GlassCard(
                  radius: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Message ${widget.otherUserName}…',
                            hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      GestureDetector(
                        onTap: _sending ? null : _send,
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                              color: palette.accent, shape: BoxShape.circle),
                          child: _sending
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black))
                              : const Icon(Icons.send_rounded,
                                  size: 15, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool mine;
  final String time;
  final Color accent;
  const _Bubble(
      {required this.text,
      required this.mine,
      required this.time,
      required this.accent});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? accent.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(text,
                style: TextStyle(
                    color: mine ? Colors.black : Colors.white,
                    fontSize: 13,
                    height: 1.35)),
            const SizedBox(height: 4),
            Text(time,
                style: TextStyle(
                    color: mine ? Colors.black54 : Colors.white38,
                    fontSize: 9.5)),
          ],
        ),
      ),
    );
  }
}

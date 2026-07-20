import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';
import '../widgets/climate_page_shell.dart';

class MicroGrantsScreen extends StatefulWidget {
  final Season season;
  const MicroGrantsScreen({super.key, required this.season});

  @override
  State<MicroGrantsScreen> createState() => _MicroGrantsScreenState();
}

class _MicroGrantsScreenState extends State<MicroGrantsScreen> {
  late Future<List<Map<String, dynamic>>?> _grantsFuture;
  final Set<String> _voting = {};

  @override
  void initState() {
    super.initState();
    _grantsFuture = BackendApi.getListOrNull('/grants');
  }

  void _refresh() {
    setState(() {
      _grantsFuture = BackendApi.getListOrNull('/grants');
    });
  }

  Future<void> _vote(String grantId) async {
    setState(() => _voting.add(grantId));
    await BackendApi.postOrNull('/grants/$grantId/vote');
    if (!mounted) return;
    setState(() => _voting.remove(grantId));
    _refresh();
  }

  Future<void> _submitProject() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final goalController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11161C),
        title: const Text('Submit a project idea',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Project title',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Funding goal',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result != true) return;
    final goal = double.tryParse(goalController.text.trim());
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        goal == null ||
        goal <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in every field with a valid goal amount.')),
      );
      return;
    }

    await BackendApi.postOrNull('/grants', body: {
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'goalAmount': goal,
    });
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Climate Micro-Grants',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Pitch a project. Get community votes. Get funded.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 18),
          GlassCard(
            radius: 20,
            borderColor: palette.accent.withValues(alpha: 0.4),
            onTap: _submitProject,
            child: Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: palette.accent, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('Submit a project idea',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5))),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Voting now',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>?>(
            future: _grantsFuture,
            builder: (context, snapshot) {
              final grants = snapshot.data ?? const [];
              if (grants.isEmpty) {
                return GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No micro-grants available yet. Submit one above to get started.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                );
              }
              return Column(
                children: grants.map((grant) {
                  final id = grant['id']?.toString() ?? '';
                  final title =
                      grant['title']?.toString() ?? 'Community project';
                  final goal = (grant['goal_amount'] as num?)?.toDouble() ?? 0;
                  final raised =
                      (grant['raised_amount'] as num?)?.toDouble() ?? 0;
                  final votes = grant['votes'] ?? 0;
                  final progress = goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;
                  final busy = _voting.contains(id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassCard(
                      radius: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 1.3)),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                              valueColor:
                                  AlwaysStoppedAnimation(palette.accent),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                  '${raised.toStringAsFixed(0)} raised of ${goal.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      fontSize: 11.5)),
                              const Spacer(),
                              Icon(Icons.how_to_vote_rounded,
                                  size: 14, color: palette.accent),
                              const SizedBox(width: 4),
                              Text('$votes votes',
                                  style: TextStyle(
                                      color: palette.accent,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color:
                                        palette.accent.withValues(alpha: 0.5)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed:
                                  busy || id.isEmpty ? null : () => _vote(id),
                              child: busy
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: palette.accent),
                                    )
                                  : Text('Vote for this project',
                                      style: TextStyle(
                                          color: palette.accent,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12.5)),
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

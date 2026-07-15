import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';

/// Mobile-adapted view of the Admin & Analytics platform described in the
/// spec (the full version is intended as a web dashboard). This screen
/// gives ops/moderation staff a quick-glance view on mobile; a separate
/// web admin app should be built for full user/marketplace/grant management.
class AdminDashboardScreen extends StatefulWidget {
  final Season season;
  const AdminDashboardScreen({super.key, required this.season});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, dynamic>?> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = BackendApi.getOrNull('/admin/summary');
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Admin & Analytics',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Platform-wide impact overview',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 18),
          FutureBuilder<Map<String, dynamic>?>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              final summary = snapshot.data ?? const {};
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _MetricCard(
                          label: 'Total users',
                          value: '${summary['totalUsers'] ?? '—'}',
                          icon: Icons.people_alt_rounded,
                          color: palette.accent),
                      _MetricCard(
                          label: 'Actions logged',
                          value: '${summary['totalActions'] ?? '—'}',
                          icon: Icons.verified_rounded,
                          color: palette.accentSoft),
                      _MetricCard(
                          label: 'Pending verification',
                          value: '${summary['pendingVerifications'] ?? '—'}',
                          icon: Icons.pending_actions_rounded,
                          color: const Color(0xFFFFC24B)),
                      _MetricCard(
                          label: 'Active grants',
                          value: '${summary['totalGrants'] ?? '—'}',
                          icon: Icons.volunteer_activism_rounded,
                          color: palette.accent),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('Moderation queue',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _QueueTile(
                      label: 'Verification submissions pending review',
                      count: summary['pendingVerifications'] ?? 0,
                      color: palette.accent),
                  _QueueTile(
                      label: 'Active hero challenges',
                      count: summary['activeChallenges'] ?? 0,
                      color: palette.accentSoft),
                  const SizedBox(height: 8),
                  Text(
                    'Marketplace-report and community-flag moderation aren\'t wired up in this backend yet — those need dedicated tables and a reviewer role before they can show real data here.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10.5, height: 1.4),
                  ),
                  const SizedBox(height: 22),
                  const Text('Disaster monitoring',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  GlassCard(
                    radius: 20,
                    borderColor: const Color(0xFFE85C5C).withValues(alpha: 0.4),
                    child: Row(
                      children: [
                        const Icon(Icons.flood_rounded, color: Color(0xFFE85C5C)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                              '${summary['highSeverityAlerts'] ?? 0} active high-severity alert${(summary['highSeverityAlerts'] ?? 0) == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _QueueTile(
      {required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 16,
        child: Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(100)),
              child: Text('$count',
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

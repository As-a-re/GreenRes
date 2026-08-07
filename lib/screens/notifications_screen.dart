import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import 'floodwatch_screen.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';

class NotificationsScreen extends StatelessWidget {
  final Season season;
  const NotificationsScreen({super.key, required this.season});

  Future<List<Map<String, dynamic>>?> _loadAlerts() =>
      BackendApi.getListOrNull('/alerts');

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(season);
    return ClimatePageShell(
      season: season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notifications',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Map<String, dynamic>>?>(
            future: _loadAlerts(),
            builder: (context, snapshot) {
              final alerts = snapshot.data ?? const [];
              if (alerts.isEmpty) {
                return GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No notifications yet. We will surface alerts and climate updates here once they are available.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                );
              }
              return Column(
                children: alerts
                    .map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            radius: 20,
                            opacity: 0.11,
                            borderColor: palette.accent.withValues(alpha: 0.28),
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        FloodWatchScreen(season: season))),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: palette.accent
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Icon(
                                      Icons.notifications_active_rounded,
                                      color: palette.accent,
                                      size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(alert['title']?.toString() ?? '',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text(alert['message']?.toString() ?? '',
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.55),
                                              fontSize: 11.5)),
                                      const SizedBox(height: 6),
                                      Text(
                                          alert['created_at']?.toString() ?? '',
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.35),
                                              fontSize: 10.5)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

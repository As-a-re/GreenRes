import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/weather_background.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';
import 'offline_mode_screen.dart';

class ClimateSosScreen extends StatefulWidget {
  final Season season;
  const ClimateSosScreen({super.key, required this.season});

  @override
  State<ClimateSosScreen> createState() => _ClimateSosScreenState();
}

const _alertTypeMeta = {
  'flood': (label: 'Flood', icon: Icons.flood_rounded),
  'heatwave': (label: 'Heatwave', icon: Icons.thermostat_rounded),
  'drought': (label: 'Drought', icon: Icons.grain_rounded),
  'air_quality': (label: 'Air quality', icon: Icons.air_rounded),
  'wildfire': (label: 'Wildfire', icon: Icons.local_fire_department_rounded),
  'storm': (label: 'Storm', icon: Icons.thunderstorm_rounded),
};

class _ClimateSosScreenState extends State<ClimateSosScreen> {
  late Future<List<Map<String, dynamic>>?> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = BackendApi.getListOrNull('/alerts');
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return WeatherBackground(
      season: widget.season,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 4),
                const Text('Climate SOS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>?>(
              future: _alertsFuture,
              builder: (context, snapshot) {
                final alerts = (snapshot.data ?? const [])
                    .where((a) => a['resolved'] != true)
                    .toList();
                alerts.sort((a, b) {
                  const order = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
                  return (order[a['severity']] ?? 4)
                      .compareTo(order[b['severity']] ?? 4);
                });

                if (alerts.isEmpty) {
                  return GlassCard(
                    radius: 24,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: palette.accent, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'No active alerts right now. We\'ll notify you the moment something changes.',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12.5,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final topAlert = alerts.first;
                final topSeverityColor = _severityColor(topAlert['severity']);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      radius: 24,
                      borderColor: topSeverityColor.withValues(alpha: 0.5),
                      opacity: 0.16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: topSeverityColor, shape: BoxShape.circle),
                            child: Icon(
                                _iconFor(topAlert['alert_type']?.toString()),
                                color: Colors.black,
                                size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(topAlert['title']?.toString() ?? 'Active alert',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                const SizedBox(height: 3),
                                Text(
                                    '${topAlert['location_label'] ?? 'Unknown area'} · ${(topAlert['severity']?.toString() ?? 'medium').toUpperCase()} severity',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('All active alerts (${alerts.length})',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...alerts.map((a) {
                      final color = _severityColor(a['severity']);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          radius: 16,
                          borderColor: color.withValues(alpha: 0.35),
                          child: Row(
                            children: [
                              Icon(_iconFor(a['alert_type']?.toString()),
                                  color: color, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a['title']?.toString() ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600)),
                                    Text(a['location_label']?.toString() ?? '',
                                        style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 10.5)),
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
            const SizedBox(height: 24),
            _SosAction(
                icon: Icons.menu_book_rounded,
                label: 'Survival guides (offline-ready)',
                color: palette.accent,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => OfflineModeScreen(season: widget.season)))),
            const SizedBox(height: 12),
            _SosAction(
                icon: Icons.wifi_off_rounded,
                label: 'Enable offline emergency mode',
                color: palette.accentSoft,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => OfflineModeScreen(season: widget.season)))),
          ],
        ),
      ),
    );
  }

  Color _severityColor(dynamic severity) {
    switch (severity) {
      case 'critical':
      case 'high':
        return const Color(0xFFE85C5C);
      case 'medium':
        return const Color(0xFFFFC24B);
      default:
        return const Color(0xFF5EC8D8);
    }
  }

  IconData _iconFor(String? type) => _alertTypeMeta[type]?.icon ?? Icons.warning_amber_rounded;
}

class _SosAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SosAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

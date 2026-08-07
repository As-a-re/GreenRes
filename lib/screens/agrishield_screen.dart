import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';

class AgriShieldScreen extends StatefulWidget {
  final Season season;
  const AgriShieldScreen({super.key, required this.season});

  @override
  State<AgriShieldScreen> createState() => _AgriShieldScreenState();
}

const _generalCrops = [
  ('Cassava', 'Drought-tolerant, good for most soils', Icons.grass_rounded),
  ('Maize', 'Needs consistent rainfall or irrigation', Icons.eco_rounded),
  (
    'Okra',
    'Warm-season crop, moderate water needs',
    Icons.local_florist_rounded
  ),
];

class _AgriShieldScreenState extends State<AgriShieldScreen> {
  late Future<List<Map<String, dynamic>>?> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = BackendApi.getListOrNull('/alerts');
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      children: [
        const Text('AgriShield',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Climate risk awareness for smallholder farmers',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        const SizedBox(height: 18),
        FutureBuilder<List<Map<String, dynamic>>?>(
          future: _alertsFuture,
          builder: (context, snapshot) {
            final alerts = (snapshot.data ?? const [])
                .where((a) =>
                    a['resolved'] != true &&
                    ['drought', 'wildfire', 'heatwave', 'storm']
                        .contains(a['alert_type']))
                .toList();

            final drought = alerts.where((a) => a['alert_type'] == 'drought');
            final other = alerts.where((a) => a['alert_type'] != 'drought');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _AlertTile(
                            icon: Icons.grain_rounded,
                            label: 'Drought risk',
                            status: drought.isEmpty
                                ? 'No active alerts'
                                : '${drought.length} active',
                            color: drought.isEmpty
                                ? palette.accent
                                : const Color(0xFFFFC24B))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _AlertTile(
                            icon: Icons.warning_amber_rounded,
                            label: 'Other climate risk',
                            status: other.isEmpty
                                ? 'No active alerts'
                                : '${other.length} active',
                            color: other.isEmpty
                                ? palette.accent
                                : const Color(0xFFE85C5C))),
                  ],
                ),
                if (alerts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ...alerts.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          radius: 16,
                          child: Row(
                            children: [
                              const Icon(Icons.warning_rounded,
                                  color: Color(0xFFFFC24B), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                    '${a['title'] ?? ''} — ${a['location_label'] ?? ''}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        const Text('General crop guidance',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
            'General reference info, not personalized to your soil or exact location',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4), fontSize: 10.5)),
        const SizedBox(height: 12),
        ..._generalCrops.map((crop) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                radius: 16,
                child: Row(
                  children: [
                    Icon(crop.$3, color: palette.accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(crop.$1,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600)),
                          Text(crop.$2,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 8),
        Text(
          'AgriShield doesn\'t yet have a hyperlocal weather or soil-suitability integration — that\'s the natural next step for this module.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10.5,
              height: 1.4),
        ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final String label, status;
  final Color color;
  const _AlertTile(
      {required this.icon,
      required this.label,
      required this.status,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
          const SizedBox(height: 2),
          Text(status,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

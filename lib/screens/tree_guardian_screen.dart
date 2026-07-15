import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';
import '../widgets/climate_page_shell.dart';

class TreeGuardianScreen extends StatefulWidget {
  final Season season;
  const TreeGuardianScreen({super.key, required this.season});

  @override
  State<TreeGuardianScreen> createState() => _TreeGuardianScreenState();
}

class _TreeGuardianScreenState extends State<TreeGuardianScreen> {
  late Future<List<Map<String, dynamic>>?> _treesFuture;

  @override
  void initState() {
    super.initState();
    _treesFuture = BackendApi.getListOrNull('/trees');
  }

  void _refresh() {
    setState(() {
      _treesFuture = BackendApi.getListOrNull('/trees');
    });
  }

  Future<void> _registerTree() async {
    final speciesController = TextEditingController();
    final locationController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11161C),
        title: const Text('Register a tree',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: speciesController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Species',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: locationController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
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
            child: const Text('Register'),
          ),
        ],
      ),
    );

    if (result != true || speciesController.text.trim().isEmpty) return;

    final treeId =
        'GR-TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    await BackendApi.postOrNull('/trees', body: {
      'species': speciesController.text.trim(),
      'treeId': treeId,
      'locationLabel': locationController.text.trim().isEmpty
          ? null
          : locationController.text.trim(),
      'health': 1.0,
    });
    _refresh();
  }

  String _formatAge(String? plantedAt) {
    if (plantedAt == null) return 'Recently added';
    final date = DateTime.tryParse(plantedAt);
    if (date == null) return 'Recently added';
    final days = DateTime.now().difference(date).inDays;
    if (days < 1) return 'Planted today';
    if (days < 30) return '$days day${days == 1 ? '' : 's'} old';
    if (days < 365) return '${(days / 30).floor()} month${(days / 30).floor() == 1 ? '' : 's'} old';
    return '${(days / 365).floor()} year${(days / 365).floor() == 1 ? '' : 's'} old';
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
              const Expanded(
                child: Text('Smart Tree Guardian',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ),
              GlassCard(
                radius: 14,
                padding: const EdgeInsets.all(10),
                onTap: _registerTree,
                child: Icon(Icons.add_rounded, color: palette.accent, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Track every tree you\'ve planted, for life',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 18),
          FutureBuilder<List<Map<String, dynamic>>?>(
            future: _treesFuture,
            builder: (context, snapshot) {
              final trees = snapshot.data ?? const [];

              final avgHealth = trees.isEmpty
                  ? 0.0
                  : trees.fold<double>(
                          0,
                          (sum, t) =>
                              sum + ((t['health'] as num?)?.toDouble() ?? 0)) /
                      trees.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _Stat(
                              label: 'Trees planted',
                              value: '${trees.length}',
                              color: palette.accent)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _Stat(
                              label: 'Avg. health',
                              value: trees.isEmpty
                                  ? '—'
                                  : '${(avgHealth * 100).toStringAsFixed(0)}%',
                              color: palette.accentSoft)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Your trees',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (trees.isEmpty)
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No trees recorded yet. Tap + above to register one you\'ve planted.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    ...trees.map((tree) {
                      final species =
                          tree['species']?.toString() ?? 'Native tree';
                      final treeId = tree['tree_id']?.toString() ?? 'Tree';
                      final locationLabel =
                          tree['location_label']?.toString();
                      final age = _formatAge(tree['planted_at']?.toString());
                      final health =
                          (tree['health'] as num?)?.toDouble() ?? 0.8;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          radius: 22,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(colors: [
                                        palette.accent,
                                        palette.accentSoft
                                      ]),
                                    ),
                                    child: const Icon(Icons.park_rounded,
                                        color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(species,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                        const SizedBox(height: 3),
                                        Text('$treeId · $age',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.5),
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  ImpactRing(
                                    value: health,
                                    color: health > 0.75
                                        ? palette.accent
                                        : (health > 0.5
                                            ? const Color(0xFFFFC24B)
                                            : const Color(0xFFE85C5C)),
                                    size: 42,
                                    center: Text('${(health * 100).toInt()}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              if (locationLabel != null &&
                                  locationLabel.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.place_rounded,
                                        size: 14, color: palette.accent),
                                    const SizedBox(width: 5),
                                    Text(locationLabel,
                                        style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.6),
                                            fontSize: 11.5)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';
import '../widgets/climate_page_shell.dart';

class FloodWatchScreen extends StatefulWidget {
  final Season season;
  const FloodWatchScreen({super.key, required this.season});

  @override
  State<FloodWatchScreen> createState() => _FloodWatchScreenState();
}

const _alertIcons = {
  'flood': Icons.flood_rounded,
  'heatwave': Icons.thermostat_rounded,
  'drought': Icons.grain_rounded,
  'air_quality': Icons.air_rounded,
  'wildfire': Icons.local_fire_department_rounded,
  'storm': Icons.thunderstorm_rounded,
};

class _FloodWatchScreenState extends State<FloodWatchScreen> {
  late Future<List<Map<String, dynamic>>?> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = BackendApi.getListOrNull('/alerts');
  }

  void _refresh() {
    setState(() {
      _alertsFuture = BackendApi.getListOrNull('/alerts');
    });
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

  Future<void> _reportAlert() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final locationController = TextEditingController();
    String alertType = 'flood';
    String severity = 'medium';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF11161C),
          title: const Text('Report a climate risk',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: alertType,
                  dropdownColor: const Color(0xFF11161C),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Type',
                      labelStyle: TextStyle(color: Colors.white54)),
                  items: _alertIcons.keys
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => alertType = v ?? alertType),
                ),
                DropdownButtonFormField<String>(
                  initialValue: severity,
                  dropdownColor: const Color(0xFF11161C),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Severity',
                      labelStyle: TextStyle(color: Colors.white54)),
                  items: const ['low', 'medium', 'high', 'critical']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => severity = v ?? severity),
                ),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Title',
                      labelStyle: TextStyle(color: Colors.white54)),
                ),
                TextField(
                  controller: messageController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Details',
                      labelStyle: TextStyle(color: Colors.white54)),
                ),
                TextField(
                  controller: locationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Location',
                      labelStyle: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Report'),
            ),
          ],
        ),
      ),
    );

    if (result != true ||
        titleController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      return;
    }

    await BackendApi.postOrNull('/alerts', body: {
      'alertType': alertType,
      'title': titleController.text.trim(),
      'message': messageController.text.trim(),
      'severity': severity,
      if (locationController.text.trim().isNotEmpty)
        'locationLabel': locationController.text.trim(),
    });
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ClimatePageShell(
      season: widget.season,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('FloodWatch Africa',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                GlassCard(
                    radius: 14,
                    padding: const EdgeInsets.all(10),
                    onTap: _reportAlert,
                    child: const Icon(Icons.add_location_alt_rounded,
                        color: Colors.white, size: 20)),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Stylized map surface — placeholder for a real map SDK integration.
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          palette.accentSoft.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.4)
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          CustomPaint(
                              painter: _GridPainter(
                                  color: Colors.white.withValues(alpha: 0.06)),
                              size: Size.infinite),
                          Center(
                            child: Text(
                              'Map placeholder — wire a mapping SDK\nto plot real alert coordinates here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  fontSize: 11,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 32,
                  right: 32,
                  bottom: 16,
                  child: GlassCard(
                    radius: 20,
                    opacity: 0.2,
                    child: Row(
                      children: [
                        const _Legend(color: Color(0xFFE85C5C), label: 'High'),
                        const SizedBox(width: 14),
                        const _Legend(
                            color: Color(0xFFFFC24B), label: 'Moderate'),
                        const SizedBox(width: 14),
                        _Legend(color: palette.accent, label: 'Low'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 190,
            child: FutureBuilder<List<Map<String, dynamic>>?>(
              future: _alertsFuture,
              builder: (context, snapshot) {
                final alerts = snapshot.data ?? const [];
                if (alerts.isEmpty) {
                  return GlassCard(
                    radius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No live alerts available right now.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.5,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final a = alerts[i];
                    final color = _severityColor(a['severity']);
                    final icon = _alertIcons[a['alert_type']] ??
                        Icons.warning_amber_rounded;
                    final title = a['title']?.toString() ?? 'Alert';
                    final severity =
                        (a['severity']?.toString() ?? 'medium').toUpperCase();
                    final location = a['location_label']?.toString() ?? '';
                    return GlassCard(
                      radius: 18,
                      borderColor: color.withValues(alpha: 0.4),
                      child: SizedBox(
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(icon, color: color, size: 16),
                              const SizedBox(width: 6),
                              Text(severity,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 8),
                            Text(title,
                                maxLines: 2,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3)),
                            const Spacer(),
                            if (location.isNotEmpty)
                              Text(location,
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  const _GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

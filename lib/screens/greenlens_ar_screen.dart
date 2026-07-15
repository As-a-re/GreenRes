import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';

class GreenLensArScreen extends StatefulWidget {
  final Season season;
  const GreenLensArScreen({super.key, required this.season});

  @override
  State<GreenLensArScreen> createState() => _GreenLensArScreenState();
}

class _GreenLensArScreenState extends State<GreenLensArScreen> {
  int _mode = 0;
  late Future<List<Map<String, dynamic>>?> _projectionsFuture;

  @override
  void initState() {
    super.initState();
    _projectionsFuture = BackendApi.getListOrNull('/ar/projections');
  }

  String _label(String? mode) {
    switch (mode) {
      case 'flood':
        return 'Flood levels';
      case 'heatwave':
        return 'Heat impact';
      case 'drought':
        return 'Drought severity';
      case 'wildfire':
        return 'Wildfire risk';
      case 'air_quality':
        return 'Air quality';
      case 'storm':
        return 'Storm risk';
      default:
        return mode ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A2E22), Color(0xFF0B140F)],
              ),
            ),
          ),
        ),
        FutureBuilder<List<Map<String, dynamic>>?>(
          future: _projectionsFuture,
          builder: (context, snapshot) {
            final projections = snapshot.data ?? const [];
            final safeMode = _mode < projections.length ? _mode : 0;
            final level = projections.isEmpty
                ? 0.5
                : ((projections[safeMode]['level'] as num?)?.toDouble() ?? 0.5);
            return Positioned.fill(
              child: CustomPaint(
                  painter: _ArOverlayPainter(color: palette.accent, level: level)),
            );
          },
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const Expanded(
                      child: Text('GreenLens AR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const Spacer(),
              FutureBuilder<List<Map<String, dynamic>>?>(
                future: _projectionsFuture,
                builder: (context, snapshot) {
                  final projections = snapshot.data ?? const [];
                  if (projections.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        radius: 20,
                        opacity: 0.18,
                        child: Text(
                          'No active climate alerts to project right now — this view lights up when there\'s real regional alert data.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11.5,
                              height: 1.4),
                        ),
                      ),
                    );
                  }
                  final safeMode = _mode < projections.length ? _mode : 0;
                  final current = projections[safeMode];
                  final activeAlerts = current['active_alerts'] ?? 0;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GlassCard(
                          radius: 20,
                          opacity: 0.18,
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: palette.accent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Simulated overlay for ${_label(current['mode']?.toString())}: based on $activeAlerts active alert${activeAlerts == 1 ? '' : 's'} of this type right now.',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 11.5,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: projections.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) => GlassChip(
                            label: _label(projections[i]['mode']?.toString()),
                            accent: palette.accent,
                            selected: safeMode == i,
                            onTap: () => setState(() => _mode = i),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                margin: const EdgeInsets.only(bottom: 28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: palette.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArOverlayPainter extends CustomPainter {
  final Color color;
  final double level;
  const _ArOverlayPainter({required this.color, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final waterline = size.height * (1 - level.clamp(0.0, 1.0) * 0.5);
    final path = Path()
      ..moveTo(0, waterline)
      ..quadraticBezierTo(
          size.width * 0.25, waterline - 14, size.width * 0.5, waterline)
      ..quadraticBezierTo(size.width * 0.75, waterline + 14, size.width, waterline)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, waterline), Offset(size.width, waterline), linePaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArOverlayPainter oldDelegate) =>
      oldDelegate.level != level;
}

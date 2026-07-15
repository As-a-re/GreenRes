import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/season_theme.dart';

/// Full-bleed animated backdrop: gradient sky + season-appropriate
/// particle field (rain, snow, falling leaves, petals, sun rays, aurora).
/// Drop this behind any screen's content with a Stack.
class WeatherBackground extends StatefulWidget {
  final Season season;
  final Widget child;
  final bool dim; // slightly darken for readability behind dense content

  const WeatherBackground({
    super.key,
    required this.season,
    required this.child,
    this.dim = true,
  });

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Particle> _particles;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..repeat();
    _particles = _spawnParticles(widget.season);
  }

  @override
  void didUpdateWidget(covariant WeatherBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.season != widget.season) {
      _particles = _spawnParticles(widget.season);
    }
  }

  List<_Particle> _spawnParticles(Season season) {
    final count = switch (season) {
      Season.rain => 90,
      Season.winter => 70,
      Season.fall => 40,
      Season.spring => 45,
      Season.aurora => 60,
      Season.summer => 18,
    };
    return List.generate(count, (i) {
      return _Particle(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        size: 2 + _rand.nextDouble() * (season == Season.fall ? 10 : 4),
        speed: 0.15 + _rand.nextDouble() * 0.6,
        drift: (_rand.nextDouble() - 0.5) * 0.6,
        phase: _rand.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base sky gradient
        DecoratedBox(
          decoration:
              BoxDecoration(gradient: SeasonTheme.gradientFor(widget.season)),
        ),
        // Soft radial glow accent (gives depth, feels "alive")
        Align(
          alignment: widget.season == Season.summer
              ? Alignment.topRight
              : Alignment.topLeft,
          child: Transform.translate(
            offset: const Offset(-60, -60),
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    palette.accent.withValues(alpha: 0.35),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
        ),
        // Particle field
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _WeatherPainter(
                season: widget.season,
                t: _controller.value,
                particles: _particles,
                color: palette.particle,
              ),
              size: Size.infinite,
            );
          },
        ),
        if (widget.dim) Container(color: Colors.black.withValues(alpha: 0.18)),
        widget.child,
      ],
    );
  }
}

class _Particle {
  final double x, y, size, speed, drift, phase;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.phase,
  });
}

class _WeatherPainter extends CustomPainter {
  final Season season;
  final double t; // 0..1 looping animation clock
  final List<_Particle> particles;
  final Color color;

  _WeatherPainter({
    required this.season,
    required this.t,
    required this.particles,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (season) {
      case Season.rain:
        _paintRain(canvas, size);
        break;
      case Season.winter:
        _paintSnow(canvas, size);
        break;
      case Season.fall:
        _paintLeaves(canvas, size);
        break;
      case Season.spring:
        _paintPetals(canvas, size);
        break;
      case Season.summer:
        _paintSunRays(canvas, size);
        break;
      case Season.aurora:
        _paintAurora(canvas, size);
        break;
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final p in particles) {
      final progress = (p.y + t * p.speed * 6) % 1.2;
      final dx = p.x * size.width + sin(p.phase) * 6;
      final dy = progress * size.height * 1.1 - size.height * 0.1;
      final end = Offset(dx - 3, dy + 16 + p.size);
      canvas.drawLine(Offset(dx, dy), end, paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.85);
    for (final p in particles) {
      final progress = (p.y + t * p.speed * 1.4) % 1.15;
      final dx =
          p.x * size.width + sin(t * 2 * pi + p.phase) * 14 * p.drift.abs();
      final dy = progress * size.height * 1.1 - size.height * 0.1;
      canvas.drawCircle(Offset(dx, dy), p.size * 0.6, paint);
    }
  }

  void _paintLeaves(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFE8A23A),
      const Color(0xFFB25A2A),
      const Color(0xFFD9673F),
      const Color(0xFF8C4A1E),
    ];
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final progress = (p.y + t * p.speed * 1.1) % 1.15;
      final sway = sin(t * 2 * pi * 1.3 + p.phase) * 26;
      final dx = p.x * size.width + sway;
      final dy = progress * size.height * 1.1 - size.height * 0.1;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.85);
      final angle = t * 2 * pi * 2 + p.phase;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, -p.size)
        ..quadraticBezierTo(p.size, 0, 0, p.size)
        ..quadraticBezierTo(-p.size, 0, 0, -p.size);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _paintPetals(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (p.y + t * p.speed * 0.9) % 1.15;
      final sway = sin(t * 2 * pi + p.phase) * 20;
      final dx = p.x * size.width + sway;
      final dy = progress * size.height * 1.1 - size.height * 0.1;
      final paint = Paint()..color = color.withValues(alpha: 0.8);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(t * 2 * pi + p.phase);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: p.size * 1.4, height: p.size * 0.8),
          paint);
      canvas.restore();
    }
  }

  void _paintSunRays(Canvas canvas, Size size) {
    // A gentle rotating sunburst + a few floating light motes.
    final center = Offset(size.width * 0.82, size.height * 0.1);
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.28), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: 260));
    canvas.drawCircle(center, 260, rayPaint);

    final motePaint = Paint()..color = color.withValues(alpha: 0.5);
    for (final p in particles) {
      final dy = p.y * size.height + sin(t * 2 * pi + p.phase) * 18;
      final dx = p.x * size.width + cos(t * 2 * pi + p.phase) * 14;
      canvas.drawCircle(Offset(dx, dy), p.size * 0.5, motePaint);
    }
  }

  void _paintAurora(Canvas canvas, Size size) {
    // Flowing ribbon bands across the top third of the screen.
    for (int band = 0; band < 3; band++) {
      final path = Path();
      final baseY = size.height * (0.12 + band * 0.07);
      path.moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 20) {
        final y = baseY +
            sin((x / size.width * 2 * pi) + t * 2 * pi + band) *
                (18 + band * 6);
        path.lineTo(x, y);
      }
      final paint = Paint()
        ..color = color.withValues(alpha: 0.10 + band * 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawPath(path, paint);
    }
    // Twinkling stars below the aurora bands.
    final starPaint = Paint()..color = Colors.white;
    for (final p in particles) {
      final twinkle = (sin(t * 2 * pi * 3 + p.phase) + 1) / 2;
      starPaint.color = Colors.white.withValues(alpha: 0.15 + twinkle * 0.6);
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height),
          p.size * 0.35, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter oldDelegate) => true;
}

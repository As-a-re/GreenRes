import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';
import '../services/location_service.dart';

/// Combines three of the requested features into one real, working screen:
/// - Hyperlocal weather (live forecast at the user's exact coordinates,
///   via the free Open-Meteo API — see backend/src/routes/weather.ts for
///   the honest note on how this differs from a full NASA POWER +
///   crowdsourced-station bias-correction pipeline)
/// - Location-aware climate issue detection (real nearby alerts within
///   50km, sorted by distance)
/// - AI Climate Coach briefing (Claude-generated if ANTHROPIC_API_KEY is
///   configured on the backend, otherwise a rules-based summary built
///   from the same real data — labeled either way, never presented as
///   more than it is)
class LocalClimateScreen extends StatefulWidget {
  final Season season;
  const LocalClimateScreen({super.key, required this.season});

  @override
  State<LocalClimateScreen> createState() => _LocalClimateScreenState();
}

class _LocalClimateScreenState extends State<LocalClimateScreen> {
  ({double latitude, double longitude})? _coords;
  bool _locating = true;
  bool _locationDenied = false;
  Future<Map<String, dynamic>?>? _weatherFuture;
  Future<Map<String, dynamic>?>? _briefingFuture;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    setState(() => _locating = true);
    final coords = await LocationService.getCurrentLocation();
    if (!mounted) return;

    if (coords == null) {
      // Fall back to a saved home location on the profile, if any.
      final profile = await BackendApi.getOrNull('/profiles/me');
      final lat = profile?['home_latitude'];
      final lng = profile?['home_longitude'];
      if (lat != null && lng != null) {
        setState(() {
          _coords = (
            latitude: (lat as num).toDouble(),
            longitude: (lng as num).toDouble()
          );
          _locating = false;
        });
        _loadData();
        return;
      }
      setState(() {
        _locating = false;
        _locationDenied = true;
      });
      return;
    }

    setState(() {
      _coords = coords;
      _locating = false;
    });
    _loadData();
  }

  void _loadData() {
    final c = _coords;
    if (c == null) return;
    setState(() {
      _weatherFuture = BackendApi.getOrNull(
          '/weather/hyperlocal?lat=${c.latitude}&lng=${c.longitude}');
      _briefingFuture = BackendApi.getOrNull(
          '/climate-briefing?lat=${c.latitude}&lng=${c.longitude}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);

    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Local Climate Center',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Live weather, nearby risks, and your personal coach',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 18),
          if (_locating)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child:
                  Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else if (_locationDenied)
            GlassCard(
              radius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_off_rounded, color: palette.accent),
                  const SizedBox(height: 10),
                  const Text('Location needed',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    'This screen needs your location to show real weather and nearby climate alerts. Allow location access, or set a home location in Settings.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.5,
                        height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _resolveLocation,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Try again',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // AI Climate Coach briefing
            FutureBuilder<Map<String, dynamic>?>(
              future: _briefingFuture,
              builder: (context, snapshot) {
                final briefing = snapshot.data;
                final loading =
                    snapshot.connectionState == ConnectionState.waiting;
                final source = briefing?['narrativeSource']?.toString();
                return GlassCard(
                  radius: 24,
                  opacity: 0.15,
                  borderColor: palette.accent.withValues(alpha: 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: palette.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14)),
                            child: Icon(Icons.psychology_rounded,
                                color: palette.accent, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('AI Climate Coach',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ),
                          if (source != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(100)),
                              child: Text(
                                  source == 'claude'
                                      ? 'AI-generated'
                                      : 'Rules-based',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (loading)
                        Text('Thinking about your local conditions…',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12.5))
                      else
                        Text(
                          briefing?['narrative']?.toString() ??
                              'Could not load your briefing right now.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              height: 1.5),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Hyperlocal weather
            const Text('Hyperlocal weather',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Live forecast for your exact coordinates',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10.5)),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>?>(
              future: _weatherFuture,
              builder: (context, snapshot) {
                final weather = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  );
                }
                if (weather == null) {
                  return GlassCard(
                    radius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Text('Could not load live weather right now.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12.5)),
                  );
                }
                final current = weather['current'] as Map<String, dynamic>?;
                final daily = (weather['dailyForecast'] as List?) ?? const [];
                final suggestions =
                    (weather['suggestions'] as List?) ?? const [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassCard(
                      radius: 22,
                      child: Row(
                        children: [
                          Icon(Icons.thermostat_rounded,
                              color: palette.accent, size: 32),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${current?['temperatureC']?.toStringAsFixed(0) ?? '—'}°C',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700)),
                                Text(current?['condition']?.toString() ?? '',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.6),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  'Humidity ${current?['humidityPercent'] ?? '—'}%',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 10.5)),
                              Text(
                                  'Wind ${current?['windSpeedKmh']?.toStringAsFixed(0) ?? '—'} km/h',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 10.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...suggestions.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              radius: 14,
                              child: Row(
                                children: [
                                  Icon(Icons.lightbulb_rounded,
                                      color: palette.accent, size: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(s.toString(),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              height: 1.4))),
                                ],
                              ),
                            ),
                          )),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: daily.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final d = daily[i] as Map<String, dynamic>;
                          return GlassCard(
                            radius: 16,
                            child: SizedBox(
                              width: 100,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      (d['date']?.toString() ?? '')
                                          .split('-')
                                          .skip(1)
                                          .join('/'),
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.5),
                                          fontSize: 10)),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${d['maxTempC']?.toStringAsFixed(0)}° / ${d['minTempC']?.toStringAsFixed(0)}°',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${d['precipitationProbabilityPercent'] ?? 0}% rain',
                                      style: TextStyle(
                                          color: palette.accent, fontSize: 10)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Nearby alerts
            const Text('Nearby climate alerts',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>?>(
              future: _briefingFuture,
              builder: (context, snapshot) {
                final nearby =
                    (snapshot.data?['nearbyAlerts'] as List?) ?? const [];
                if (nearby.isEmpty) {
                  return GlassCard(
                    radius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Text('No active alerts within 50km of you.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12.5)),
                  );
                }
                return Column(
                  children: nearby.map((a) {
                    final alert = a as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        radius: 16,
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFFFC24B), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(alert['title']?.toString() ?? '',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12.5)),
                            ),
                            Text(
                                '${(alert['distanceKm'] as num?)?.toStringAsFixed(0) ?? '—'}km',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

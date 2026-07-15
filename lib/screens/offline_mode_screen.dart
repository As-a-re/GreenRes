import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/weather_background.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';

class OfflineModeScreen extends StatefulWidget {
  final Season season;
  const OfflineModeScreen({super.key, required this.season});

  @override
  State<OfflineModeScreen> createState() => _OfflineModeScreenState();
}

class _OfflineModeScreenState extends State<OfflineModeScreen> {
  late Future<List<Map<String, dynamic>>?> _guidesFuture;

  @override
  void initState() {
    super.initState();
    _guidesFuture = BackendApi.getListOrNull('/offline/guides');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WeatherBackground(
        season: widget.season,
        dim: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Row(children: [
                IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18)),
                const SizedBox(width: 4),
                const Text('Offline Emergency Guides',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 20),
              GlassCard(
                radius: 26,
                opacity: 0.18,
                borderColor: const Color(0xFFE85C5C).withValues(alpha: 0.5),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFFE85C5C)),
                      child: const Icon(Icons.wifi_off_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    const Text('Emergency reference guides',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'These guides load once and are meant to stay useful even with a weak signal — but true offline caching (so they open with zero connection at all) isn\'t wired into the app yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12.5,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              FutureBuilder<List<Map<String, dynamic>>?>(
                future: _guidesFuture,
                builder: (context, snapshot) {
                  final guides = snapshot.data ?? const [];
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                          child: CircularProgressIndicator(color: Colors.white)),
                    );
                  }
                  if (guides.isEmpty) {
                    return GlassCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No emergency guides have been published yet.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12.5),
                      ),
                    );
                  }
                  guides.sort((a, b) =>
                      ((a['priority'] as num?) ?? 99).compareTo((b['priority'] as num?) ?? 99));
                  return Column(
                    children: guides.map((g) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          radius: 16,
                          onTap: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF11161C),
                              title: Text(g['title']?.toString() ?? '',
                                  style: const TextStyle(color: Colors.white)),
                              content: SingleChildScrollView(
                                child: Text(g['content']?.toString() ?? '',
                                    style: const TextStyle(
                                        color: Colors.white70, height: 1.5)),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.menu_book_rounded,
                                  color: SeasonTheme.of(widget.season).accent,
                                  size: 19),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(g['title']?.toString() ?? '',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600))),
                              Icon(Icons.chevron_right_rounded,
                                  color: Colors.white.withValues(alpha: 0.4)),
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
        ),
      ),
    );
  }
}

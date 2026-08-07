import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/weather_background.dart';

/// Shown when the app can't reach the GreenRes backend at all (as opposed
/// to reaching it and finding no session — that's [LoginScreen]'s job).
/// This is a setup/connectivity problem, not an auth problem, so it gets
/// its own screen with actionable next steps instead of a confusing
/// perpetual "signing in" state.
class SetupScreen extends StatefulWidget {
  final Future<void> Function()? onRetry;
  const SetupScreen({super.key, this.onRetry});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    await widget.onRetry?.call();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(Season.spring);
    return WeatherBackground(
      season: Season.spring,
      dim: true,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GlassCard(
              radius: 24,
              opacity: 0.16,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(Icons.cloud_off_rounded,
                        color: palette.accent, size: 34),
                  ),
                  const SizedBox(height: 12),
                  const Text('Can\'t reach the GreenRes backend',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Text(
                    'The app is configured to talk to:',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      BackendApi.baseUrl,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'To fix this:',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _step(
                      '1',
                      'Start the backend locally: in /backend run '
                          '"npm install && cp .env.example .env" — fill in your '
                          'Supabase project URL and keys — then "npm run dev".'),
                  _step(
                      '2',
                      'Or point the app at an already-deployed backend by '
                          'launching with --dart-define=GREENRES_API_BASE_URL='
                          'https://your-backend.example.com/api/v1'),
                  _step(
                      '3',
                      'If you\'re running on a physical device or emulator, '
                          '"localhost" won\'t reach your computer — use your machine\'s '
                          'LAN IP or 10.0.2.2 for the Android emulator instead.'),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _checking ? null : _retry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _checking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Text('Try again',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.45)),
          ),
        ],
      ),
    );
  }
}

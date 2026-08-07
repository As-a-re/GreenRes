import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import '../services/session_store.dart';
import '../theme/season_theme.dart';
import '../widgets/weather_background.dart';
import 'login_screen.dart';
import 'main_nav.dart';
import 'setup_screen.dart';

enum _GateState { loading, needsSetup, authenticated, unauthenticated }

/// The app's real entry point after the splash beat. Decides between three
/// destinations: [SetupScreen] if the backend can't be reached at all,
/// [LoginScreen] if it's reachable but there's no valid session, or
/// [MainNav] if a persisted session still checks out with the backend.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  _GateState _state = _GateState.loading;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final reachable = await BackendApi.checkHealth();
    if (!reachable) {
      if (mounted) setState(() => _state = _GateState.needsSetup);
      return;
    }

    await SessionStore.load();
    final token = SessionStore.accessToken;
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _state = _GateState.unauthenticated);
      return;
    }

    try {
      await BackendApi.getCurrentUser();
      if (mounted) setState(() => _state = _GateState.authenticated);
    } catch (_) {
      await SessionStore.clear();
      if (mounted) setState(() => _state = _GateState.unauthenticated);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _GateState.loading:
        return const WeatherBackground(
          season: Season.spring,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      case _GateState.needsSetup:
        return SetupScreen(onRetry: _retry);
      case _GateState.authenticated:
        return const MainNav(initialSeason: Season.spring);
      case _GateState.unauthenticated:
        return const LoginScreen();
    }
  }

  Future<void> _retry() async {
    setState(() => _state = _GateState.loading);
    await _bootstrap();
  }
}

import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import '../services/session_store.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/weather_background.dart';
import 'main_nav.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  final _season = Season.spring;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isSignUp) {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() => _error = 'Passwords do not match');
          return;
        }

        final result = await BackendApi.signUp(
          _emailController.text,
          _passwordController.text,
          fullName: _nameController.text,
        );
        final token = result['access_token']?.toString();
        if (token != null && token.isNotEmpty) {
          await SessionStore.setAccessToken(token);
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const OnboardingScreen(),
            ),
            (_) => false,
          );
          return;
        }

        setState(
            () => _error = result['message']?.toString() ?? 'Sign up failed');
      } else {
        final result = await BackendApi.signIn(
          _emailController.text,
          _passwordController.text,
        );
        final token = result['access_token']?.toString();
        if (token != null && token.isNotEmpty) {
          await SessionStore.setAccessToken(token);
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const MainNav(initialSeason: Season.spring),
            ),
            (_) => false,
          );
          return;
        }

        setState(
            () => _error = result['message']?.toString() ?? 'Sign in failed');
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(_season);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WeatherBackground(
        season: _season,
        dim: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          palette.accent.withValues(alpha: 0.95),
                          palette.accentSoft,
                        ]),
                      ),
                      child: const Icon(Icons.public_rounded,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 18),
                    const Text('GreenRes Ecosystem',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                        _isSignUp
                            ? 'Create your account and start tracking climate impact'
                            : 'Sign in to access your live climate workspace',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13.5)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              GlassCard(
                radius: 24,
                opacity: 0.16,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _AuthModeButton(
                              label: 'Sign in',
                              selected: !_isSignUp,
                              onTap: () => setState(() {
                                _isSignUp = false;
                                _error = null;
                              }),
                            ),
                          ),
                          Expanded(
                            child: _AuthModeButton(
                              label: 'Create account',
                              selected: _isSignUp,
                              onTap: () => setState(() {
                                _isSignUp = true;
                                _error = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isSignUp) ...[
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (_error != null) ...[
                      Text(_error!,
                          style: const TextStyle(
                              color: Color(0xFFFF8A80), fontSize: 12.5)),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(_isSignUp ? 'Create account' : 'Sign in',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _isSignUp = !_isSignUp;
                          _error = null;
                        }),
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Sign in'
                              : 'Need an account? Create one',
                          style: TextStyle(color: palette.accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AuthModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

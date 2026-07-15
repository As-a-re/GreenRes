import 'package:shared_preferences/shared_preferences.dart';

/// Holds the current Supabase access token in memory and persists it to
/// disk so the person stays signed in across app restarts. Call
/// [SessionStore.load] once during startup before reading [accessToken].
class SessionStore {
  SessionStore._();

  static const String _tokenKey = 'greenres_access_token';

  static String? accessToken;
  static bool _loaded = false;

  /// Loads any previously-persisted token from disk. Safe to call more
  /// than once; subsequent calls are no-ops.
  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      accessToken = prefs.getString(_tokenKey);
    } catch (_) {
      // Storage unavailable (e.g. some test environments) — fall back to
      // an in-memory-only session for this run.
      accessToken = null;
    } finally {
      _loaded = true;
    }
  }

  static Future<void> setAccessToken(String? token) async {
    accessToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null || token.isEmpty) {
        await prefs.remove(_tokenKey);
      } else {
        await prefs.setString(_tokenKey, token);
      }
    } catch (_) {
      // Best effort — the in-memory token above still lets this session work.
    }
  }

  static Future<void> clear() async {
    accessToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {}
  }

  /// Generic boolean preference storage, used for lightweight UI settings
  /// (e.g. the toggles on the Settings screen) that don't warrant their
  /// own backend field.
  static Future<bool?> getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }
}

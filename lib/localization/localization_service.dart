import 'package:flutter/foundation.dart';
import '../services/session_store.dart';

/// App language. Twi (Akan) is the first local-language integration;
/// more can be added by extending [_strings] and [AppLocale].
///
/// IMPORTANT: the Twi strings below — especially the voice-assistant
/// lines, since those get spoken aloud — are a first-pass translation and
/// have NOT been reviewed by a native speaker. Ship-blocking for a real
/// release: get these checked before they go out, particularly the
/// accessibility voice content where a wrong word is more disruptive than
/// a typo in a menu. English remains the default; Twi is opt-in via
/// Settings so nobody hears unreviewed translations without choosing to.
enum AppLocale { english, twi }

class LocalizationService extends ChangeNotifier {
  LocalizationService._();
  static final LocalizationService instance = LocalizationService._();

  static const _storageKey = 'app_locale';

  AppLocale _locale = AppLocale.english;
  AppLocale get locale => _locale;

  Future<void> load() async {
    final saved = await SessionStore.getBool('$_storageKey.is_twi');
    _locale = saved == true ? AppLocale.twi : AppLocale.english;
    notifyListeners();
  }

  Future<void> setLocale(AppLocale locale) async {
    _locale = locale;
    await SessionStore.setBool('$_storageKey.is_twi', locale == AppLocale.twi);
    notifyListeners();
  }

  String t(String key) {
    return _strings[key]?[_locale] ?? _strings[key]?[AppLocale.english] ?? key;
  }
}

/// Shorthand accessor used throughout the app: `L.t('nav_home')`.
String tr(String key) => LocalizationService.instance.t(key);

const Map<String, Map<AppLocale, String>> _strings = {
  // --- Navigation ---
  'nav_home': {AppLocale.english: 'Home', AppLocale.twi: 'Fie'},
  'nav_track': {AppLocale.english: 'Track', AppLocale.twi: 'Hwɛ'},
  'nav_learn': {AppLocale.english: 'Learn', AppLocale.twi: 'Sua'},
  'nav_market': {AppLocale.english: 'Market', AppLocale.twi: 'Gua'},
  'nav_passport': {AppLocale.english: 'Passport', AppLocale.twi: 'Krataa'},

  // --- Common actions ---
  'action_log': {AppLocale.english: 'Log an action', AppLocale.twi: 'Kyerɛw wo dwuma'},
  'action_wallet': {AppLocale.english: 'Wallet', AppLocale.twi: 'Sika kotoku'},
  'action_alerts': {AppLocale.english: 'Alerts', AppLocale.twi: 'Kɔkɔbɔ'},
  'action_weather': {AppLocale.english: 'Weather', AppLocale.twi: 'Ewiem tebea'},
  'action_settings': {AppLocale.english: 'Settings', AppLocale.twi: 'Nhyehyɛe'},

  // --- Voice assistant spoken lines ---
  'voice_welcome': {
    AppLocale.english:
        'Welcome to GreenRes Ecosystem. This app helps you track climate actions, get weather updates, and connect with your community. Say "help" at any time to hear available voice commands.',
    AppLocale.twi:
        'Akwaaba wɔ GreenRes Ecosystem mu. App yi boa wo ma wohu wo nsakrae a ɛfa ewiem tebea ho, ewiem tebea nsɛm foforo, ne sɛnea wobɛka wo mpɔtam hɔ nnipa ho asɛm. Ka "help" bere biara na ate nne mmara a wubetumi de ayɛ adwuma.',
  },
  'voice_help': {
    AppLocale.english:
        'You can say: home, track, learn, market, passport, wallet, alerts, weather, or settings to open that screen. Say "read screen" to hear a summary of what\'s on screen now.',
    AppLocale.twi:
        'Wubetumi aka: fie, hwɛ, sua, gua, krataa, sika kotoku, kɔkɔbɔ, ewiem tebea, anaasɛ nhyehyɛe na ama saa screen no abue. Ka "read screen" na ate nea ɛwɔ screen no so seesei.',
  },
  'voice_not_understood': {
    AppLocale.english:
        'Sorry, I didn\'t catch that. Say "help" to hear what you can say.',
    AppLocale.twi: 'Kafra, mante no yiye. Ka "help" na ate nea wubetumi aka.',
  },
  'voice_listening': {
    AppLocale.english: 'Listening…',
    AppLocale.twi: 'Meretie…',
  },
};

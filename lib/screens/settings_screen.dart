import 'package:flutter/material.dart';
import '../services/backend_api.dart';
import '../services/session_store.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Season season;
  const SettingsScreen({super.key, required this.season});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = BackendApi.getOrNull('/profiles/me');
  }

  void _refresh() {
    setState(() {
      _profileFuture = BackendApi.getOrNull('/profiles/me');
    });
  }

  Future<void> _editProfile(Map<String, dynamic>? current) async {
    final nameController =
        TextEditingController(text: current?['display_name']?.toString() ?? '');
    final bioController =
        TextEditingController(text: current?['bio']?.toString() ?? '');
    final locationController =
        TextEditingController(text: current?['location']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11161C),
        title:
            const Text('Edit profile', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Display name',
                    labelStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: locationController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Location',
                    labelStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: bioController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Bio',
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (nameController.text.trim().isEmpty) return;

    await BackendApi.patchOrNull('/profiles/me', body: {
      'displayName': nameController.text.trim(),
      'location': locationController.text.trim(),
      'bio': bioController.text.trim(),
    });
    _refresh();
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('$feature isn\'t built yet — coming in a future update.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Settings',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final displayName =
                  profile?['display_name']?.toString() ?? 'GreenRes User';
              final email = profile?['email']?.toString() ?? '';
              return GlassCard(
                radius: 22,
                onTap: () => _editProfile(profile),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: [palette.accent, palette.accentSoft])),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          Text(email,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_rounded, color: palette.accent, size: 18),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          const _SectionLabel('Account'),
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              return _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: 'Edit profile',
                onTap: () => _editProfile(snapshot.data),
              );
            },
          ),
          _SettingsTile(
              icon: Icons.lock_outline_rounded,
              label: 'Privacy & security',
              onTap: () => _comingSoon('Privacy & security settings')),
          _SettingsTile(
              icon: Icons.badge_outlined,
              label: 'Verification documents',
              onTap: () => _comingSoon('Verification document upload')),
          const SizedBox(height: 18),
          const _SectionLabel('Preferences'),
          Text(
              'Weather mood: ${SeasonTheme.of(widget.season).label} — cycle it from the Home tab',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
          const SizedBox(height: 10),
          _PersistedToggleTile(
              storageKey: 'settings_push_notifications',
              icon: Icons.notifications_none_rounded,
              label: 'Push notifications',
              defaultValue: true,
              accent: palette.accent),
          _PersistedToggleTile(
              storageKey: 'settings_data_saver',
              icon: Icons.wifi_off_rounded,
              label: 'Data saver mode',
              defaultValue: false,
              accent: palette.accent),
          const SizedBox(height: 18),
          const _SectionLabel('Support'),
          _SettingsTile(
              icon: Icons.help_outline_rounded,
              label: 'Help center',
              onTap: () => _comingSoon('The help center')),
          _SettingsTile(
              icon: Icons.description_outlined,
              label: 'Terms & privacy policy',
              onTap: () => _comingSoon('Terms & privacy policy pages')),
          _SettingsTile(
              icon: Icons.info_outline_rounded,
              label: 'About GreenRes',
              onTap: () => _comingSoon('The about page')),
          const SizedBox(height: 22),
          GlassCard(
            radius: 18,
            onTap: () async {
              await SessionStore.clear();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Row(
              children: [
                Icon(Icons.logout_rounded, color: Color(0xFFE85C5C), size: 19),
                SizedBox(width: 12),
                Text('Log out',
                    style: TextStyle(
                        color: Color(0xFFE85C5C),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.label, this.onTap})
      : trailing = null;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 16,
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 19),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600))),
            if (trailing != null) ...[
              Text(trailing!,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11.5)),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }
}

/// A toggle whose value is persisted to disk via SharedPreferences. Note:
/// this saves a *preference*, but nothing in the backend currently reads
/// it — there's no push-notification delivery system or bandwidth-aware
/// image loading wired up yet, so toggling these doesn't yet change app
/// behavior beyond remembering your choice.
class _PersistedToggleTile extends StatefulWidget {
  final String storageKey;
  final IconData icon;
  final String label;
  final bool defaultValue;
  final Color accent;
  const _PersistedToggleTile({
    required this.storageKey,
    required this.icon,
    required this.label,
    required this.defaultValue,
    required this.accent,
  });
  @override
  State<_PersistedToggleTile> createState() => _PersistedToggleTileState();
}

class _PersistedToggleTileState extends State<_PersistedToggleTile> {
  bool _value = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _value = widget.defaultValue;
    _load();
  }

  Future<void> _load() async {
    final stored = await SessionStore.getBool(widget.storageKey);
    if (mounted) {
      setState(() {
        _value = stored ?? widget.defaultValue;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        radius: 16,
        child: Row(
          children: [
            Icon(widget.icon, color: Colors.white70, size: 19),
            const SizedBox(width: 12),
            Expanded(
                child: Text(widget.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600))),
            Switch(
              value: _value,
              activeThumbColor: widget.accent,
              onChanged: _loaded
                  ? (v) {
                      setState(() => _value = v);
                      SessionStore.setBool(widget.storageKey, v);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

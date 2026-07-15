import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import 'checkout_screen.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';

class WalletScreen extends StatefulWidget {
  final Season season;
  const WalletScreen({super.key, required this.season});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<Map<String, dynamic>?> _walletFuture;
  late Future<List<Map<String, dynamic>>?> _redemptionsFuture;
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _walletFuture = BackendApi.getOrNull('/rewards/wallet');
    _redemptionsFuture = BackendApi.getListOrNull('/rewards/redemptions');
  }

  Future<void> _redeem(String rewardType, String label) async {
    final controller = TextEditingController(text: '100');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11161C),
        title: Text('Redeem for $label',
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Credits to redeem',
            labelStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final credits = int.tryParse(controller.text.trim());
    if (credits == null || credits <= 0) return;

    setState(() => _redeeming = true);
    try {
      await BackendApi.post('/rewards/redemptions', body: {
        'rewardType': rewardType,
        'credits': credits,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Redeemed $credits credits for $label')),
      );
      setState(_refresh);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('ClimateCash Wallet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Your GreenRes Credits, in one place',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 18),
          FutureBuilder<Map<String, dynamic>?>(
            future: _walletFuture,
            builder: (context, snapshot) {
              final wallet = snapshot.data;
              final balance = wallet?['credits_balance'];
              final tier = wallet?['tier_name']?.toString();
              return GlassCard(
                radius: 26,
                opacity: 0.15,
                borderColor: palette.accent.withValues(alpha: 0.4),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Available balance',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12)),
                        Icon(Icons.toll_rounded,
                            color: palette.accent, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(balance == null ? '—' : '$balance credits',
                        style: TextStyle(
                            color: palette.accent,
                            fontSize: 30,
                            fontWeight: FontWeight.w800)),
                    if (tier != null) ...[
                      const SizedBox(height: 4),
                      Text(
                          '${tier[0].toUpperCase()}${tier.substring(1)} tier',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12)),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: _WalletAction(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Donate',
                      color: palette.accentSoft,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                              season: widget.season,
                              purposeOverride: 'donation'))))),
              const SizedBox(width: 10),
              Expanded(
                  child: _WalletAction(
                      icon: Icons.add_card_rounded,
                      label: 'Top up',
                      color: palette.accent,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                              season: widget.season,
                              purposeOverride: 'rewards'))))),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Redeem for',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _RedeemOption(
                      icon: Icons.phone_android_rounded,
                      label: 'Airtime',
                      color: palette.accent,
                      busy: _redeeming,
                      onTap: () => _redeem('airtime', 'Airtime'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _RedeemOption(
                      icon: Icons.wifi_rounded,
                      label: 'Data',
                      color: palette.accentSoft,
                      busy: _redeeming,
                      onTap: () => _redeem('data', 'Data'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _RedeemOption(
                      icon: Icons.directions_bus_rounded,
                      label: 'Transport',
                      color: palette.accent,
                      busy: _redeeming,
                      onTap: () =>
                          _redeem('transport_voucher', 'Transport'))),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Recent transactions',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>?>(
            future: _redemptionsFuture,
            builder: (context, snapshot) {
              final transactions = snapshot.data ?? const [];
              if (transactions.isEmpty) {
                return GlassCard(
                  radius: 16,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No redemptions yet. Redeem credits above and they\'ll show up here.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                );
              }
              return Column(
                children: transactions
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            radius: 16,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded,
                                      size: 17, color: Colors.white70),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          _rewardTypeLabel(
                                              t['reward_type']?.toString()),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5)),
                                      Text(
                                          t['status']?.toString() ?? 'pending',
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.45),
                                              fontSize: 10.5)),
                                    ],
                                  ),
                                ),
                                Text('-${t['credits_spent'] ?? 0}',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _rewardTypeLabel(String? type) {
    switch (type) {
      case 'airtime':
        return 'Airtime redemption';
      case 'data':
        return 'Data redemption';
      case 'transport_voucher':
        return 'Transport voucher';
      case 'marketplace_product':
        return 'Marketplace redemption';
      case 'donation':
        return 'Donation';
      default:
        return 'Redemption';
    }
  }
}

class _WalletAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _WalletAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RedeemOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool busy;
  final VoidCallback onTap;
  const _RedeemOption(
      {required this.icon,
      required this.label,
      required this.color,
      required this.busy,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      onTap: busy ? null : onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/weather_background.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';

class CheckoutScreen extends StatefulWidget {
  final Season season;
  final Map<String, dynamic>? listing;
  final double? amountOverride;
  final String? purposeOverride;
  const CheckoutScreen(
      {super.key,
      required this.season,
      this.listing,
      this.amountOverride,
      this.purposeOverride});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _method = 0;
  bool _paying = false;
  bool _paid = false;
  late final TextEditingController _amountController;
  final _methods = const [
    (provider: 'mtn_momo', icon: Icons.account_balance_wallet_rounded, label: 'MTN Mobile Money'),
    (provider: 'airtel_money', icon: Icons.account_balance_wallet_rounded, label: 'Airtel Money'),
    (provider: 'flutterwave', icon: Icons.credit_card_rounded, label: 'Flutterwave'),
    (provider: 'stripe', icon: Icons.credit_card_rounded, label: 'Card (Stripe)'),
  ];

  bool get _needsAmountInput =>
      widget.listing == null && widget.amountOverride == null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '50');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _subtotal {
    if (widget.amountOverride != null) return widget.amountOverride!;
    final price = widget.listing?['price'];
    if (price != null) {
      return (price is num) ? price.toDouble() : double.tryParse('$price') ?? 0;
    }
    return double.tryParse(_amountController.text.trim()) ?? 0;
  }

  double get _delivery => widget.listing != null ? 10 : 0;
  double get _total => _subtotal + _delivery;

  String get _currencySymbol {
    final currency = widget.listing?['currency']?.toString() ?? 'USD';
    return switch (currency) {
      'USD' => r'$',
      'GHS' => '₵',
      'EUR' => '€',
      'GBP' => '£',
      _ => '$currency ',
    };
  }

  String _fmt(double amount) =>
      '$_currencySymbol${amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2)}';

  Future<void> _confirm() async {
    setState(() => _paying = true);
    try {
      await BackendApi.post('/payments/intents', body: {
        'provider': _methods[_method].provider,
        'amount': _total,
        'purpose': widget.purposeOverride ??
            (widget.listing != null ? 'marketplace' : 'donation'),
      });
      if (!mounted) return;
      setState(() {
        _paying = false;
        _paid = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);

    if (_paid) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: WeatherBackground(
          season: widget.season,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GlassCard(
                  radius: 24,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: palette.accent, size: 48),
                      const SizedBox(height: 16),
                      const Text('Payment initiated',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        'Your payment intent for ${_fmt(_total)} has been recorded and is pending confirmation from your provider.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12.5,
                            height: 1.5),
                      ),
                      const SizedBox(height: 20),
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
                          onPressed: () =>
                              Navigator.of(context).popUntil((r) => r.isFirst),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Done',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WeatherBackground(
        season: widget.season,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18)),
                    const Text('Checkout',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    if (widget.listing != null)
                      GlassCard(
                        radius: 20,
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(colors: [
                                  palette.accentSoft,
                                  palette.accent
                                ]),
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      widget.listing!['title']?.toString() ??
                                          'Listing',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5)),
                                  const SizedBox(height: 3),
                                  Text(
                                      'Sold by ${widget.listing!['seller_display_name'] ?? 'GreenRes seller'}',
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                            ),
                            Text(_fmt(_subtotal),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                      )
                    else if (_needsAmountInput)
                      GlassCard(
                        radius: 20,
                        child: Row(
                          children: [
                            Icon(Icons.payments_rounded,
                                color: palette.accent, size: 20),
                            const SizedBox(width: 12),
                            const Text('Amount',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            const Spacer(),
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _amountController,
                                textAlign: TextAlign.right,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
                                decoration: const InputDecoration(
                                    isDense: true, border: InputBorder.none),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 22),
                    const Text('Payment method',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    ...List.generate(_methods.length, (i) {
                      final m = _methods[i];
                      final selected = i == _method;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          radius: 16,
                          borderColor: selected
                              ? palette.accent.withValues(alpha: 0.6)
                              : null,
                          opacity: selected ? 0.18 : 0.08,
                          onTap: () => setState(() => _method = i),
                          child: Row(
                            children: [
                              Icon(m.icon,
                                  color: selected
                                      ? palette.accent
                                      : Colors.white60,
                                  size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(m.label,
                                      style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : Colors.white70,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600))),
                              Icon(
                                  selected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: selected
                                      ? palette.accent
                                      : Colors.white30,
                                  size: 18),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    GlassCard(
                      radius: 18,
                      child: Column(
                        children: [
                          if (widget.listing != null) ...[
                            _Row(label: 'Subtotal', value: _fmt(_subtotal)),
                            const SizedBox(height: 8),
                            _Row(label: 'Delivery', value: _fmt(_delivery)),
                            const Divider(color: Colors.white12, height: 24),
                          ],
                          _Row(label: 'Total', value: _fmt(_total), bold: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _paying ? null : _confirm,
                    child: _paying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : Text('Confirm & pay ${_fmt(_total)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14.5)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _Row({required this.label, required this.value, this.bold = false});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: bold ? 0.9 : 0.6),
                fontSize: bold ? 14 : 12.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: bold ? 15 : 12.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      ],
    );
  }
}

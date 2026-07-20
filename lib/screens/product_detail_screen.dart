import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/weather_background.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';
import 'checkout_screen.dart';
import 'messaging_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Season season;
  final Map<String, dynamic> listing;
  const ProductDetailScreen(
      {super.key, required this.season, required this.listing});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _startingThread = false;

  String get _title => widget.listing['title']?.toString() ?? 'Listing';
  String get _category => widget.listing['category']?.toString() ?? 'General';
  String get _seller =>
      widget.listing['seller_display_name']?.toString() ?? 'GreenRes seller';
  String get _description =>
      widget.listing['description']?.toString() ??
      'No description provided for this listing yet.';

  String _formattedPrice() {
    final price = widget.listing['price'];
    final currency = widget.listing['currency']?.toString() ?? 'USD';
    if (price == null) return '';
    final amount = (price is num) ? price : num.tryParse('$price') ?? 0;
    final symbol = switch (currency) {
      'USD' => r'$',
      'GHS' => '₵',
      'EUR' => '€',
      'GBP' => '£',
      _ => '$currency ',
    };
    return '$symbol${amount % 1 == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2)}';
  }

  Future<void> _messageSeller() async {
    final sellerId = widget.listing['seller_id']?.toString();
    final listingId = widget.listing['id']?.toString();
    if (sellerId == null || listingId == null) return;

    setState(() => _startingThread = true);
    final thread = await BackendApi.postOrNull('/messages/threads', body: {
      'listingId': listingId,
      'sellerId': sellerId,
    });
    if (!mounted) return;
    setState(() => _startingThread = false);

    if (thread == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start a conversation. Try again.')),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MessagingScreen(
        season: widget.season,
        threadId: thread['id']?.toString() ?? '',
        otherUserName: _seller,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WeatherBackground(
        season: widget.season,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        palette.accentSoft.withValues(alpha: 0.6),
                        palette.accent.withValues(alpha: 0.35)
                      ],
                    ),
                  ),
                  child: Center(
                      child: Icon(Icons.storefront_rounded,
                          size: 90,
                          color: Colors.white.withValues(alpha: 0.9))),
                ),
                SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlassCard(
                            radius: 14,
                            padding: const EdgeInsets.all(10),
                            onTap: () => Navigator.of(context).maybePop(),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassChip(
                      label: _category, accent: palette.accent, selected: true),
                  const SizedBox(height: 12),
                  Text(_title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_formattedPrice(),
                      style: TextStyle(
                          color: palette.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 18),
                  GlassCard(
                    radius: 18,
                    onTap: _startingThread ? null : _messageSeller,
                    child: Row(
                      children: [
                        CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                palette.accent.withValues(alpha: 0.3),
                            child: const Icon(Icons.storefront_rounded,
                                color: Colors.white, size: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_seller,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              Text(
                                  widget.listing['is_verified'] == true
                                      ? 'Verified seller'
                                      : 'Marketplace seller',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        ),
                        if (_startingThread)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white54),
                          )
                        else
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: palette.accent, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Description',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(
                    _description,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => CheckoutScreen(
                                  season: widget.season,
                                  listing: widget.listing))),
                      child: const Text('Buy now',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

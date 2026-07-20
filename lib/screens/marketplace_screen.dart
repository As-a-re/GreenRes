import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';
import 'product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  final Season season;
  const MarketplaceScreen({super.key, required this.season});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late Future<List<Map<String, dynamic>>> _listingsFuture;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _listingsFuture = BackendApi.getList('/marketplace/listings');
  }

  String _formatPrice(Map<String, dynamic> item) {
    final price = item['price'];
    final currency = item['currency']?.toString() ?? 'USD';
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

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GreenRes Marketplace',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Buy, sell, exchange and donate sustainably',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13)),
              const SizedBox(height: 16),
              GlassCard(
                radius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.5), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Search upcycled goods, solar kits…',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 13)),
                    ),
                    Icon(Icons.tune_rounded, color: palette.accent, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _listingsFuture,
                builder: (context, snapshot) {
                  final listings = snapshot.data ?? const [];
                  final categories = <String>{
                    'All',
                    ...listings
                        .map((l) => l['category']?.toString())
                        .whereType<String>(),
                  }.toList();
                  return SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => GlassChip(
                        label: categories[i],
                        accent: palette.accent,
                        selected: _selectedCategory == categories[i],
                        onTap: () =>
                            setState(() => _selectedCategory = categories[i]),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _listingsFuture,
            builder: (context, snapshot) {
              final allListings = snapshot.data ?? const [];
              final listings = _selectedCategory == 'All'
                  ? allListings
                  : allListings
                      .where((l) => l['category'] == _selectedCategory)
                      .toList();

              if (allListings.isEmpty) {
                return GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No marketplace listings yet. New products will appear here once they are published.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                itemCount: listings.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, i) {
                  final item = listings[i];
                  return GlassCard(
                    radius: 20,
                    padding: const EdgeInsets.all(12),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(
                            season: widget.season, listing: item))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 84,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                palette.accentSoft.withValues(alpha: 0.4),
                                palette.accent.withValues(alpha: 0.25)
                              ],
                            ),
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: Colors.white, size: 30),
                        ),
                        const SizedBox(height: 10),
                        Text(item['title']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5)),
                        const SizedBox(height: 2),
                        Text(
                            item['seller_display_name']?.toString() ??
                                'GreenRes seller',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10.5)),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatPrice(item),
                                style: TextStyle(
                                    color: palette.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: palette.accent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle),
                              child: Icon(Icons.add_rounded,
                                  size: 14, color: palette.accent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

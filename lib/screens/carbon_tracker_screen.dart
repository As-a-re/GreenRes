import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';

/// The honest version of "automated carbon footprint tracking": real,
/// transparent emission-factor math on entries you log, with the full
/// factor table visible (see backend/src/routes/carbon-footprint.ts).
///
/// What's NOT here, and why: automatic bank-transaction categorization
/// needs a Plaid (or regional equivalent) integration — a paid financial
/// data service requiring your own API keys and a real user consent/OAuth
/// flow through your bank. Receipt OCR needs a cloud OCR service (Google
/// Vision, AWS Textract, etc.) with its own API key. Building either
/// without real credentials would mean faking the data, so both are left
/// as a clearly-labeled next step rather than simulated.
class CarbonTrackerScreen extends StatefulWidget {
  final Season season;
  const CarbonTrackerScreen({super.key, required this.season});

  @override
  State<CarbonTrackerScreen> createState() => _CarbonTrackerScreenState();
}

class _CarbonTrackerScreenState extends State<CarbonTrackerScreen> {
  Map<String, dynamic>? _factors;
  late Future<Map<String, dynamic>?> _summaryFuture;
  late Future<List<Map<String, dynamic>>?> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _loadFactors();
    _refresh();
  }

  Future<void> _loadFactors() async {
    final factors = await BackendApi.getOrNull('/carbon-footprint/factors');
    if (mounted) setState(() => _factors = factors);
  }

  void _refresh() {
    _summaryFuture = BackendApi.getOrNull('/carbon-footprint/summary');
    _expensesFuture = BackendApi.getListOrNull('/carbon-footprint/expenses');
  }

  Future<void> _addEntry() async {
    if (_factors == null) return;
    final categories = _factors!.keys.toList();
    String category = categories.first;
    final quantityController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF11161C),
          title: const Text('Log an expense', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  dropdownColor: const Color(0xFF11161C),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                      labelText: 'Category', labelStyle: TextStyle(color: Colors.white54)),
                  items: categories
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(_factors![c]['label']?.toString() ?? c,
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 8),
                Text('Unit: ${_factors![category]['unit']}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
                TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Quantity', labelStyle: TextStyle(color: Colors.white54)),
                ),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Note (optional)', labelStyle: TextStyle(color: Colors.white54)),
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
      ),
    );

    if (result != true) return;
    final quantity = double.tryParse(quantityController.text.trim());
    if (quantity == null || quantity <= 0) return;

    await BackendApi.postOrNull('/carbon-footprint/expenses', body: {
      'category': category,
      'quantity': quantity,
      if (descriptionController.text.trim().isNotEmpty)
        'description': descriptionController.text.trim(),
    });
    setState(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);
    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const Text('Carbon Footprint Tracker',
              style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Transparent, factor-based CO₂ estimates',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          const SizedBox(height: 18),
          FutureBuilder<Map<String, dynamic>?>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              final summary = snapshot.data;
              final total = (summary?['total_co2_kg'] as num?)?.toDouble() ?? 0;
              final last30 = (summary?['co2_kg_30d'] as num?)?.toDouble() ?? 0;
              return GlassCard(
                radius: 24,
                opacity: 0.14,
                borderColor: palette.accent.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Last 30 days',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                          Text('${last30.toStringAsFixed(1)} kg CO₂',
                              style: TextStyle(
                                  color: palette.accent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white12),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('All time',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                          Text('${total.toStringAsFixed(1)} kg CO₂',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          GlassCard(
            radius: 20,
            borderColor: palette.accent.withValues(alpha: 0.4),
            onTap: _factors == null ? null : _addEntry,
            child: Row(
              children: [
                Icon(Icons.add_circle_rounded, color: palette.accent, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('Log an expense',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Recent entries',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>?>(
            future: _expensesFuture,
            builder: (context, snapshot) {
              final entries = snapshot.data ?? const [];
              if (entries.isEmpty) {
                return GlassCard(
                  radius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No entries yet. Log your first expense above to start tracking.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5, height: 1.4),
                  ),
                );
              }
              return Column(
                children: entries.map((e) {
                  final label = _factors?[e['category']]?['label']?.toString() ??
                      e['category']?.toString() ??
                      'Entry';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      radius: 16,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600)),
                                if (e['description'] != null)
                                  Text(e['description'].toString(),
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.45),
                                          fontSize: 10.5)),
                              ],
                            ),
                          ),
                          Text(
                              '${(e['estimated_co2_kg'] as num?)?.toStringAsFixed(1) ?? '0'} kg',
                              style: TextStyle(
                                  color: palette.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Bank-transaction and receipt-photo auto-detection aren\'t wired up here — those need a Plaid-style bank integration and an OCR service with their own API keys. Every estimate above is transparently computed from what you log, using the factor table your backend exposes at GET /carbon-footprint/factors.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

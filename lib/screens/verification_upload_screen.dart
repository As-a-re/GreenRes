import 'package:flutter/material.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/climate_page_shell.dart';
import '../services/backend_api.dart';

class VerificationUploadScreen extends StatefulWidget {
  final Season season;
  const VerificationUploadScreen({super.key, required this.season});

  @override
  State<VerificationUploadScreen> createState() =>
      _VerificationUploadScreenState();
}

const _actionTypes = [
  ('tree_planting', 'Tree planting'),
  ('recycling', 'Recycling'),
  ('composting', 'Composting'),
  ('cycling', 'Cycling'),
  ('transport', 'Sustainable transport'),
  ('cleanup', 'Community cleanup'),
  ('water_conservation', 'Water conservation'),
  ('energy_saving', 'Energy saving'),
];

class _VerificationUploadScreenState extends State<VerificationUploadScreen> {
  String _actionType = _actionTypes.first.$1;
  final _titleController = TextEditingController();
  final _evidenceUrlController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  bool _submitting = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _evidenceUrlController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Please describe what you did.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _result = null;
    });

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    try {
      final response = await BackendApi.post('/verification/submit', body: {
        'actionType': _actionType,
        'title': _titleController.text.trim(),
        if (_evidenceUrlController.text.trim().isNotEmpty)
          'evidenceUrl': _evidenceUrlController.text.trim(),
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      });
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _result = response;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);

    if (_result != null) {
      final submission = _result!['submission'] as Map<String, dynamic>?;
      final approved = submission?['status'] == 'approved';
      final credits = _result!['creditsAwarded'] ?? 0;
      final confidence = (submission?['confidence'] as num?)?.toDouble() ?? 0;

      return ClimatePageShell(
        season: widget.season,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Row(children: [
              IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18)),
              const SizedBox(width: 4),
              const Text('Submission received',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 20),
            GlassCard(
              radius: 24,
              opacity: 0.16,
              borderColor: (approved ? palette.accent : const Color(0xFFFFC24B))
                  .withValues(alpha: 0.5),
              child: Row(
                children: [
                  ImpactRing(
                    value: confidence,
                    color: approved ? palette.accent : const Color(0xFFFFC24B),
                    size: 58,
                    center: Text('${(confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: approved
                                ? palette.accent
                                : const Color(0xFFFFC24B),
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            approved
                                ? 'Auto-approved'
                                : 'Pending manual review',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          approved
                              ? 'Photo evidence and location were provided, so this action was credited immediately. +$credits credits.'
                              : 'Add a photo link and coordinates next time for instant approval — this one will need manual follow-up.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11.5,
                              height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: palette.accent.withValues(alpha: 0.5)),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => setState(() {
                  _result = null;
                  _titleController.clear();
                  _evidenceUrlController.clear();
                  _latController.clear();
                  _lngController.clear();
                }),
                child: Text('Log another action',
                    style: TextStyle(color: palette.accent, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }

    return ClimatePageShell(
      season: widget.season,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(children: [
            IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18)),
            const SizedBox(width: 4),
            const Text('Log & verify an action',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 18),
          Text('Action type',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _actionTypes.map((t) {
              return GlassChip(
                label: t.$2,
                accent: palette.accent,
                selected: _actionType == t.$1,
                onTap: () => setState(() => _actionType = t.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          _FieldCard(
            label: 'What did you do?',
            controller: _titleController,
            hint: 'e.g. Planted 5 mangrove saplings at Lekki shoreline',
          ),
          const SizedBox(height: 12),
          _FieldCard(
            label: 'Evidence photo URL (optional)',
            controller: _evidenceUrlController,
            hint: 'https://…',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FieldCard(
                  label: 'Latitude (optional)',
                  controller: _latController,
                  hint: '6.5244',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FieldCard(
                  label: 'Longitude (optional)',
                  controller: _lngController,
                  hint: '3.3792',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Submissions with both a photo link and coordinates are approved instantly. Everything else is queued for manual review.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10.5, height: 1.4),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: Color(0xFFE85C5C), fontSize: 12)),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Submit for verification',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  const _FieldCard({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5)),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }
}

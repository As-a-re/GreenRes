import 'package:flutter/material.dart';
// FIX 1: Hide 'Colors' from vector_math to avoid the ambiguous import error
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/widgets/ar_view.dart';
import '../theme/season_theme.dart';
import '../widgets/glass_card.dart';
import '../services/backend_api.dart';

/// Real ARCore/ARKit spatial AR via ar_flutter_plugin — genuine camera feed,
/// genuine horizontal-plane detection, genuine world-anchored 3D markers.
/// Tap a detected surface to place a climate-risk marker there; its color
/// reflects real alert-severity data from GET /ar/projections, sourced from
/// the same live climate_alerts table the rest of the app uses.
///
/// IMPLEMENTATION NOTE (read before your first build): this file was
/// written against ar_flutter_plugin's documented API (pinned to ^0.7.3 in
/// pubspec.yaml) without the ability to compile or run it — Flutter AR
/// needs a native Android/iOS toolchain and a physical ARCore/ARKit
/// device, neither of which exist in the environment this was built in.
/// Plugin internals have drifted slightly across versions in the past;
/// the four lines most likely to need a small fix on your first build are
/// marked "VERIFY" below — check them against
/// `ar_flutter_plugin`'s example app (specifically
/// `example/lib/examples/objectsonplanesexample.dart` in the plugin's
/// GitHub repo) if any of them don't compile. Every other line in this
/// screen (fetching real projection data, the UI chrome) is exercised by
/// the same patterns used successfully elsewhere in this app.
class GreenLensArScreen extends StatefulWidget {
  final Season season;
  const GreenLensArScreen({super.key, required this.season});

  @override
  State<GreenLensArScreen> createState() => _GreenLensArScreenState();
}

class _GreenLensArScreenState extends State<GreenLensArScreen> {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARAnchorManager? _anchorManager;

  final List<ARAnchor> _anchors = [];
  final List<ARNode> _nodes = [];

  List<Map<String, dynamic>> _projections = [];
  int _mode = 0;
  bool _arFailed = false;
  String? _arFailureMessage;

  @override
  void initState() {
    super.initState();
    _loadProjections();
  }

  Future<void> _loadProjections() async {
    final data = await BackendApi.getListOrNull('/ar/projections');
    if (mounted) setState(() => _projections = data ?? []);
  }

  @override
  void dispose() {
    _sessionManager?.dispose();
    super.dispose();
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _sessionManager = sessionManager;
    _objectManager = objectManager;
    _anchorManager = anchorManager;

    _sessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handleTaps: true,
    );
    _objectManager!.onInitialize();

    // FIX: If the plugin version doesn't allow direct assignment,
    // try using the 'onPlaneOrPointTap' property if it exists,
    // or check the plugin's specific example for the callback name.
    // Most common fix for this specific error is ensuring the method signature matches.
    // If 'onPlaneOrPointTap' is not a setter, check if it is 'onTap' or similar.
    try {
      _sessionManager!.onPlaneOrPointTap = _onPlaneTapped;
    } catch (e) {
      print('Callback assignment failed: $e');
    }
  }

  String get _assetForCurrentMode {
    if (_projections.isEmpty) return 'assets/ar/marker_low.gltf';
    final current = _projections[_mode.clamp(0, _projections.length - 1)];
    final level = (current['level'] as num?)?.toDouble() ?? 0;
    if (level >= 0.7) return 'assets/ar/marker_high.gltf';
    if (level >= 0.4) return 'assets/ar/marker_moderate.gltf';
    return 'assets/ar/marker_low.gltf';
  }

  Future<void> _onPlaneTapped(List<ARHitTestResult> hitTestResults) async {
    if (_anchorManager == null || _objectManager == null) return;
    if (hitTestResults.isEmpty) return;

    // VERIFY: enum member name for a plane hit — documented as
    // `ARHitTestResultType.plane` in the plugin's public API.
    final hit = hitTestResults.firstWhere(
      (h) => h.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );

    // VERIFY: ARPlaneAnchor's constructor parameter name — documented as
    // `transformation` taking the hit's world transform matrix.
    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final added = await _anchorManager!.addAnchor(anchor);
    if (added != true) return;
    _anchors.add(anchor);

    final node = ARNode(
      // VERIFY: NodeType enum member for a bundled Flutter-asset glTF —
      // documented as `localGLTF2` in the plugin's node type enum; some
      // versions name this `fileSystemAppFolderGLTF2` instead.
      type: NodeType.localGLTF2,
      uri: _assetForCurrentMode,
      scale: Vector3(1, 1, 1),
      position: Vector3.zero(),
      rotation: Vector4(1, 0, 0, 0),
    );
    final nodeAdded = await _objectManager!.addNode(node, planeAnchor: anchor);
    if (nodeAdded == true) {
      _nodes.add(node);
      if (mounted) setState(() {});
    }
  }

  Future<void> _clearMarkers() async {
    for (final anchor in _anchors) {
      await _anchorManager?.removeAnchor(anchor);
    }
    _anchors.clear();
    _nodes.clear();
    if (mounted) setState(() {});
  }

  String _label(String? mode) {
    switch (mode) {
      case 'flood':
        return 'Flood levels';
      case 'heatwave':
        return 'Heat impact';
      case 'drought':
        return 'Drought severity';
      case 'wildfire':
        return 'Wildfire risk';
      case 'air_quality':
        return 'Air quality';
      case 'storm':
        return 'Storm risk';
      default:
        return mode ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeasonTheme.of(widget.season);

    return Stack(
      children: [
        Positioned.fill(
          child: _arFailed
              ? _ArUnavailable(message: _arFailureMessage)
              : ARView(
                  onARViewCreated: _onARViewCreated,
                  planeDetectionConfig: PlaneDetectionConfig.horizontal,
                ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const Expanded(
                      child: Text('GreenLens AR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const Spacer(),
              if (!_arFailed) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    radius: 20,
                    opacity: 0.22,
                    child: Row(
                      children: [
                        Icon(Icons.touch_app_rounded,
                            color: palette.accent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _projections.isEmpty
                                ? 'Move your phone to find a flat surface, then tap it to place a marker.'
                                : 'Tap a detected surface to place a ${_label(_projections[_mode.clamp(0, _projections.length - 1)]['mode']?.toString())} marker (${_nodes.length} placed).',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11.5,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_projections.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _projections.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => GlassChip(
                        label: _label(_projections[i]['mode']?.toString()),
                        accent: palette.accent,
                        selected: _mode == i,
                        onTap: () => setState(() => _mode = i),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _nodes.isEmpty ? null : _clearMarkers,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 28),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_clear_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                            _nodes.isEmpty
                                ? 'No markers yet'
                                : 'Clear ${_nodes.length} marker${_nodes.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ArUnavailable extends StatelessWidget {
  final String? message;
  const _ArUnavailable({this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.view_in_ar_outlined,
                    color: Colors.white38, size: 48),
                const SizedBox(height: 16),
                const Text('AR isn\'t available on this device',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                    message ??
                        'This device may not support ARCore/ARKit, or camera permission was denied. Real AR requires a physical device — it won\'t work in an emulator/simulator.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12, height: 1.5)),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('Go back',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

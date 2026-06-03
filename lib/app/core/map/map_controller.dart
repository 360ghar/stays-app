import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';

/// OpenFreeMap "Liberty" vector style. No API key required; OSM/OpenFreeMap
/// attribution is rendered automatically by the style and MUST NOT be hidden.
const String kLibertyStyle = 'https://tiles.openfreemap.org/styles/liberty';

/// Default initial zoom level for map views.
const double kDefaultInitialZoom = 12.0;

/// Default minimum zoom level.
const double kDefaultMinZoom = 3.0;

/// Default maximum zoom level.
const double kDefaultMaxZoom = 18.0;

/// Reusable wrapper around [MapLibreMapController] that exposes the small,
/// stable surface the feature views need (camera moves, zoom, projection).
///
/// The wrapper holds a *nullable* underlying controller because MapLibre only
/// hands the controller back asynchronously via `onMapCreated`; call [attach]
/// from that callback before invoking any camera method. All public methods
/// no-op while detached, so it is safe to call them from GetX controllers
/// whose lifecycle does not perfectly track the map widget's.
///
/// Coordinate convention: every public method here uses MapLibre's [LatLng]
/// (latitude first).
class StaysMapController {
  MapLibreMapController? _controller;

  /// The underlying MapLibre controller, or null until [attach] runs.
  MapLibreMapController? get controller => _controller;

  bool get isAttached => _controller != null;

  /// The most recent camera target, or null if the camera position is unknown.
  /// Requires the map to have been created with `trackCameraPosition: true`.
  LatLng? get center => _controller?.cameraPosition?.target;

  /// The most recent zoom level, or [kDefaultInitialZoom] if unknown.
  double get zoom => _controller?.cameraPosition?.zoom ?? kDefaultInitialZoom;

  /// Bind the live MapLibre controller. Call from `onMapCreated`.
  void attach(MapLibreMapController controller) {
    _controller = controller;
  }

  /// Instantly re-position the camera (no animation).
  Future<void> move(LatLng center, double zoom) async {
    await _controller?.moveCamera(CameraUpdate.newLatLngZoom(center, zoom));
  }

  /// Smoothly animate the camera to [center]. When [zoom] is omitted the
  /// current zoom level is preserved.
  Future<void> animateTo(
    LatLng center, {
    double? zoom,
    Duration duration = const Duration(milliseconds: 400),
  }) async {
    final controller = _controller;
    if (controller == null) return;
    final targetZoom = zoom ?? this.zoom;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(center, targetZoom),
      duration: duration,
    );
  }

  /// Zoom in one step. The map's own `MinMaxZoomPreference` clamps the result.
  Future<void> zoomIn() async {
    await _controller?.animateCamera(CameraUpdate.zoomIn());
  }

  /// Zoom out one step. The map's own `MinMaxZoomPreference` clamps the result.
  Future<void> zoomOut() async {
    await _controller?.animateCamera(CameraUpdate.zoomOut());
  }

  /// Project a geographic coordinate to a screen pixel, used to position
  /// Flutter widget overlays on top of the map. Returns null if not attached.
  Future<math.Point<num>?> toScreenLocation(LatLng latLng) async {
    final controller = _controller;
    if (controller == null) return null;
    return controller.toScreenLocation(latLng);
  }

  void dispose() {
    // MapLibreMapController is owned/disposed by the MapLibreMap widget itself;
    // we only drop our reference so stale calls become no-ops.
    _controller = null;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Whether `maplibre_gl` can actually render on the current platform.
///
/// MapLibre GL supports Android, iOS and Web. It does NOT support Windows,
/// macOS or Linux desktop, where instantiating a [MapLibreMap] throws.
/// Guarded so it never touches `dart:io` (which is unavailable on web).
bool get mapLibreSupported {
  if (kIsWeb) return true;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    // ignore: no_default_cases
    default:
      return false; // windows / macos / linux
  }
}

/// Renders the real interactive MapLibre map only where it is supported and a
/// static placeholder card with an "Open in browser" action elsewhere
/// (e.g. Windows desktop, where `maplibre_gl` has no implementation).
///
/// The [mapBuilder] is a closure so the [MapLibreMap] widget is never even
/// constructed on unsupported platforms. [latitude]/[longitude]/[zoom] are
/// used to build the OpenStreetMap fallback URL.
class SafeMap extends StatelessWidget {
  const SafeMap({
    required this.mapBuilder,
    required this.latitude,
    required this.longitude,
    super.key,
    this.zoom = 15,
    this.unsupportedMessage = 'Interactive map not available on this platform',
  });

  /// Builds the real interactive map. Only invoked on supported platforms.
  final WidgetBuilder mapBuilder;
  final double latitude;
  final double longitude;
  final double zoom;
  final String unsupportedMessage;

  @override
  Widget build(BuildContext context) {
    if (mapLibreSupported) {
      return mapBuilder(context);
    }
    return _UnsupportedMapPlaceholder(
      latitude: latitude,
      longitude: longitude,
      zoom: zoom,
      message: unsupportedMessage,
    );
  }
}

class _UnsupportedMapPlaceholder extends StatelessWidget {
  const _UnsupportedMapPlaceholder({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.message,
  });

  final double latitude;
  final double longitude;
  final double zoom;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textStyles = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 40,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textStyles.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open in browser'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInBrowser() async {
    final z = zoom.round();
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude'
      '#map=$z/$latitude/$longitude',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

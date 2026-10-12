import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/tokens.dart';
import '../l10n_ext.dart';

/// The delivery address with the shopper's dropped pin on an embedded map, and
/// a hand-off to the phone's real maps app for navigation.
///
/// ponytail: OpenStreetMap tiles via flutter_map, not google_maps_flutter.
/// Google's SDK needs an API key per platform, billing, and a key rotation
/// story for a map that is only ever looked at. OSM needs none of that. The
/// "open in Google Maps" button below still hands the driver to Google (or
/// Apple Maps on iOS), which is where navigation actually happens.
class DeliveryMap extends StatelessWidget {
  const DeliveryMap({
    super.key,
    required this.address,
    this.latitude,
    this.longitude,
    this.height = 180,
  });

  final String address;
  final double? latitude;
  final double? longitude;
  final double height;

  bool get _hasPin => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = context.l;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (_hasPin)
                  SizedBox(height: height, child: _Map(point: LatLng(latitude!, longitude!)))
                else
                  Container(
                    height: height,
                    color: c.surface,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_off_outlined, size: 26, color: c.textDisabled),
                        const SizedBox(height: 8),
                        Text(
                          l.noMapPin,
                          style: TextStyle(fontSize: 12, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  color: c.card,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place_outlined, size: 18, color: c.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          address.isEmpty ? l.noResults : address,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _openMaps(context),
                icon: const Icon(Icons.navigation_outlined, size: 18),
                label: Text(l.openInMaps),
              ),
            ),
            if (_hasPin) ...[
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => _copyCoordinates(context),
                child: const Icon(Icons.copy_outlined, size: 18),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Google Maps' universal URL. Android and iOS both route it to the installed
  /// Google Maps app when present and to the browser otherwise, so there is no
  /// per-platform scheme to maintain.
  Future<void> _openMaps(BuildContext context) async {
    final query = _hasPin
        ? '$latitude,$longitude'
        : address;

    if (query.trim().isEmpty) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l.somethingWentWrong)),
        );
      }
    }
  }

  Future<void> _copyCoordinates(BuildContext context) async {
    final l = context.l;

    await Clipboard.setData(ClipboardData(text: '$latitude,$longitude'));

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.coordinatesCopied)));
    }
  }
}

class _Map extends StatelessWidget {
  const _Map({required this.point});

  final LatLng point;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: 15.5,
        // Pan and zoom, but no rotation: a two-finger twist while pinching
        // leaves the map crooked with no obvious way back. Dragging the map
        // holds the gesture, so the page scrolls only from outside it —
        // the same behaviour as a map embedded in a web page.
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.flingAnimation,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // OSM's tile policy requires a real identifying agent.
          userAgentPackageName: 'ge.komero.komero_mobile',
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 40,
              height: 40,
              alignment: Alignment.topCenter,
              child: Icon(Icons.location_on, size: 40, color: c.error),
            ),
          ],
        ),
      ],
    );
  }
}

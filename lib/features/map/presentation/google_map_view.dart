import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../domain/map_marker.dart';

/// Google Maps rendering backend. Used whenever the center falls outside
/// Korea's bounding box.
class GoogleMapView extends StatelessWidget {
  const GoogleMapView({
    super.key,
    required this.centerLat,
    required this.centerLng,
    required this.markers,
    required this.onMarkerTap,
  });

  final double centerLat;
  final double centerLng;
  final List<AppMapMarker> markers;
  final void Function(AppMapMarker marker) onMarkerTap;

  @override
  Widget build(BuildContext context) {
    final byId = {for (final m in markers) m.id: m};

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(centerLat, centerLng),
        zoom: 15,
      ),
      markers: markers
          .map(
            (m) => gmaps.Marker(
              markerId: gmaps.MarkerId(m.id),
              position: gmaps.LatLng(m.lat, m.lng),
              infoWindow: gmaps.InfoWindow(title: m.title),
              onTap: () {
                final marker = byId[m.id];
                if (marker != null) onMarkerTap(marker);
              },
            ),
          )
          .toSet(),
    );
  }
}

/// Provider-agnostic marker passed into [AppMapView].
class AppMapMarker {
  const AppMapMarker({
    required this.id,
    required this.lat,
    required this.lng,
    required this.title,
    this.subtitle = '',
    this.payload = const {},
  });

  final String id;
  final double lat;
  final double lng;
  final String title;
  final String subtitle;

  /// Original restaurant JSON (category, address, badge counts, ...) so the
  /// marker-tap bottom sheet can render full details without a second lookup.
  final Map<String, dynamic> payload;
}

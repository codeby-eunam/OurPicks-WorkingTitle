import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/map_marker.dart';
import 'google_map_view.dart';
import 'kakao_map_view.dart';

/// Returns true when [lat]/[lng] fall inside Korea's rough bounding box
/// (lat 33~39, lng 124~132), matching the plan's country-branch rule.
bool isKoreaCoordinate(double lat, double lng) {
  return lat >= 33 && lat <= 39 && lng >= 124 && lng <= 132;
}

/// Single entry point screens use for map rendering. Internally picks
/// [KakaoMapView] or [GoogleMapView] based on [centerLat]/[centerLng] so
/// callers never need to know which map SDK is behind it.
class AppMapView extends StatelessWidget {
  const AppMapView({
    super.key,
    required this.centerLat,
    required this.centerLng,
    this.markers = const [],
    this.onMarkerTap,
  });

  final double centerLat;
  final double centerLng;
  final List<AppMapMarker> markers;
  final void Function(AppMapMarker marker)? onMarkerTap;

  void _handleMarkerTap(BuildContext context, AppMapMarker marker) {
    onMarkerTap?.call(marker);
    showRestaurantMarkerSheet(context, marker);
  }

  @override
  Widget build(BuildContext context) {
    if (isKoreaCoordinate(centerLat, centerLng)) {
      return KakaoMapView(
        centerLat: centerLat,
        centerLng: centerLng,
        markers: markers,
        onMarkerTap: (marker) => _handleMarkerTap(context, marker),
      );
    }

    return GoogleMapView(
      centerLat: centerLat,
      centerLng: centerLng,
      markers: markers,
      onMarkerTap: (marker) => _handleMarkerTap(context, marker),
    );
  }
}

/// Bottom sheet shown when a restaurant marker is tapped, mirroring the
/// place summary the RN app shows via KakaoWebView/restaurant-detail.
Future<void> showRestaurantMarkerSheet(
  BuildContext context,
  AppMapMarker marker,
) {
  final payload = marker.payload;
  final category = payload['category_name']?.toString() ?? '';
  final address = payload['road_address_name']?.toString().isNotEmpty == true
      ? payload['road_address_name'].toString()
      : payload['address_name']?.toString() ?? '';

  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              marker.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (category.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                category,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if (address.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                address,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

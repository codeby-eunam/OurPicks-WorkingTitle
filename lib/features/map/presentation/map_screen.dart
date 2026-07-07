import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/app_colors.dart';
import '../application/map_providers.dart';
import '../domain/map_marker.dart';
import 'app_map_view.dart';

/// Restaurant map screen: shows nearby places as markers, tap for details.
/// If no [initialLat]/[initialLng] is passed (e.g. deep-linked from
/// mode-select), falls back to the device's current GPS location.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.initialLat, this.initialLng});

  final double? initialLat;
  final double? initialLng;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  double? _lat;
  double? _lng;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _lat = widget.initialLat;
      _lng = widget.initialLng;
    } else {
      _resolveCurrentLocation();
    }
  }

  Future<void> _resolveCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = '위치 권한이 필요합니다.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '위치를 가져올 수 없습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }
    if (_lat == null || _lng == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final query = NearbyQuery(lat: _lat!, lng: _lng!);
    final nearbyAsync = ref.watch(nearbyRestaurantsProvider(query));

    return Scaffold(
      appBar: AppBar(title: const Text('지도')),
      body: nearbyAsync.when(
        data: (restaurants) {
          final markers = restaurants
              .map(
                (r) => AppMapMarker(
                  id: r.id,
                  lat: r.lat,
                  lng: r.lng,
                  title: r.placeName,
                  payload: r.toJson(),
                ),
              )
              .toList();

          return AppMapView(
            centerLat: _lat!,
            centerLng: _lng!,
            markers: markers,
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(child: Text('가게 정보를 불러오지 못했습니다: $err')),
      ),
    );
  }
}

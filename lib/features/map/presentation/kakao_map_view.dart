import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;

import '../../../core/theme/app_colors.dart';
import '../data/map_config.dart';
import '../domain/map_marker.dart';

/// Kakao Maps rendering backend (webview_flutter wrapping Kakao Maps JS SDK).
/// Used when the given center falls inside Korea's bounding box.
class KakaoMapView extends StatelessWidget {
  const KakaoMapView({
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
    if (MapConfig.kakaoJsKey.isEmpty) {
      return const _MissingKakaoKeyNotice();
    }

    final kakaoMarkers = markers
        .map(
          (m) => kakao.Marker(
            markerId: m.id,
            latLng: kakao.LatLng(m.lat, m.lng),
            infoWindowContent: m.title,
          ),
        )
        .toList();

    return kakao.KakaoMap(
      center: kakao.LatLng(centerLat, centerLng),
      markers: kakaoMarkers,
      onMarkerTap: (markerId, latLng, zoomLevel) {
        for (final marker in markers) {
          if (marker.id == markerId) {
            onMarkerTap(marker);
            break;
          }
        }
      },
    );
  }
}

class _MissingKakaoKeyNotice extends StatelessWidget {
  const _MissingKakaoKeyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: const Text(
        'Kakao Maps JS 키가 설정되지 않았어요.\n'
        '--dart-define=KAKAO_JS_KEY=xxx 로 실행해주세요.\n'
        '(Kakao Developers 콘솔 → 앱 설정 → 플랫폼 → Web 등록)',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

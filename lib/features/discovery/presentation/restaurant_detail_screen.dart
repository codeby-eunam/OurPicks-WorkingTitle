import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/kakao_webview.dart';

/// Port of app/restaurant-detail.tsx.
class RestaurantDetailScreen extends StatelessWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.placeId,
    this.placeUrl,
  });

  final String placeId;
  final String? placeUrl;

  @override
  Widget build(BuildContext context) {
    final webUrl = (placeUrl != null && placeUrl!.isNotEmpty)
        ? placeUrl!
        : 'https://place.map.kakao.com/$placeId';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.chevron_left, size: 32),
                ),
              ),
            ),
            Expanded(
              child: ClipRect(child: KakaoWebView(uri: webUrl)),
            ),
          ],
        ),
      ),
    );
  }
}

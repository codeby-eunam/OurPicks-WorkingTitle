import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/restaurant.dart';
import '../../../shared/services/restaurant_api.dart';
import '../../../shared/widgets/floating_contact_button.dart';
import '../domain/category_map.dart';

/// Port of app/mode-select.tsx: fetches nearby restaurants for the selected
/// categories, then routes to /swipe (>16 결과) or /tournament (<=16).
class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({
    super.key,
    required this.lat,
    required this.lng,
    required this.locationName,
    required this.categoryFilters,
  });

  final double lat;
  final double lng;
  final String locationName;
  final String categoryFilters;

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _autoFetch();
  }

  List<String> _resolveCategories() {
    final filterIds = widget.categoryFilters.split(',').where((s) => s.isNotEmpty).toList();
    final ids = filterIds.isEmpty ? ['all'] : filterIds;
    if (ids.contains('all')) return kCategoryMap['all']!;
    final categories = <String>{};
    for (final id in ids) {
      categories.addAll(kCategoryMap[id] ?? const []);
    }
    return categories.isEmpty ? kCategoryMap['all']! : categories.toList();
  }

  Future<void> _autoFetch() async {
    setState(() => _error = false);
    try {
      final categories = _resolveCategories();
      final api = RestaurantApi();
      final results = await Future.wait(
        categories.map((cat) => api.fetchNearby(lat: widget.lat, lng: widget.lng, category: cat, radius: kAutoRadiusMeters)),
      );

      final seen = <String>{};
      final restaurants = <Restaurant>[];
      for (final list in results) {
        for (final r in list) {
          if (seen.add(r.id)) restaurants.add(r);
        }
      }

      if (!mounted) return;

      if (restaurants.isEmpty) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('가게 없음'),
            content: const Text('근처 3km 내에 가게가 없습니다.\n위치나 카테고리를 바꿔보세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('돌아가기'),
              ),
            ],
          ),
        );
        return;
      }

      final extra = {'restaurants': restaurants, 'locationName': widget.locationName};
      if (restaurants.length > kSwipeThreshold) {
        context.pushReplacement('/swipe', extra: extra);
      } else {
        context.pushReplacement('/tournament', extra: extra);
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _error
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('😥', style: TextStyle(fontSize: 52)),
                          const SizedBox(height: 12),
                          const Text(
                            '가게 정보를 불러오지 못했습니다.',
                            style: TextStyle(fontSize: 16, color: Color(0xFF374151), fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _autoFetch,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            child: const Text('다시 시도'),
                          ),
                          TextButton(onPressed: () => context.pop(), child: const Text('돌아가기')),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 12),
                          const Text('맛집을 찾고 있어요', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('📍 ${widget.locationName} · 반경 3km', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                        ],
                      ),
              ),
            ),
            const FloatingContactButton(),
          ],
        ),
      ),
    );
  }
}

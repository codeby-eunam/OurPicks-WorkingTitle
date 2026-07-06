import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/restaurant.dart';
import '../../../shared/models/restaurant_category.dart';
import '../../../shared/services/analytics_service.dart';
import '../../../shared/services/restaurant_badge.dart';
import '../../../shared/services/restaurant_stats_service.dart';
import '../../../shared/widgets/floating_contact_button.dart';
import '../../auth/application/user_notifier.dart';

String _buildMapUrl(Restaurant r) {
  if (r.naverUrl != null && r.naverUrl!.isNotEmpty) {
    return r.naverUrl!.replaceFirst(RegExp('^http://', caseSensitive: false), 'https://');
  }
  final query = '${r.placeName} ${r.roadAddressName.isNotEmpty ? r.roadAddressName : r.addressName}';
  return 'https://search.naver.com/search.naver?query=${Uri.encodeComponent(query)}';
}

/// Port of app/result.tsx: winner card + confetti celebration.
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.winner});

  final Restaurant winner;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late final ConfettiController _confettiController;
  int? _winCount;
  bool _logged = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();
    _loadWinCount();
    WidgetsBinding.instance.addPostFrameCallback((_) => _logSelection());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadWinCount() async {
    final map = await RestaurantStatsService.instance.getWinCounts([widget.winner.id]);
    if (mounted) setState(() => _winCount = map[widget.winner.id]);
  }

  Future<void> _logSelection() async {
    if (_logged) return;
    final userState = ref.read(userProvider);
    final category = categoryLabelFor(widget.winner.categoryName);

    AnalyticsService.instance.logRestaurantSelected(
      widget.winner.id, widget.winner.placeName, category, 'random', '',
      userId: userState.user?.userId,
    );

    if (userState.isLoggedIn && userState.user != null) {
      _logged = true;
      try {
        final response = await ApiClient.instance.dio.post('/api/userlog', data: {
          'userId': userState.user!.kakaoId,
          'restaurantId': widget.winner.id,
          'restaurantName': widget.winner.placeName,
        });
        debugPrint(response.data['skipped'] == true
            ? '[userlog] 오늘 이미 선택한 맛집, 저장 건너뜀 ⏭️ ${widget.winner.placeName}'
            : '[userlog] 저장 완료 ✅ ${widget.winner.placeName}');
      } catch (e) {
        debugPrint('[userlog] 저장 실패 ❌ $e');
      }
    }
  }

  Future<void> _handleShare() async {
    final r = widget.winner;
    try {
      await SharePlus.instance.share(
        ShareParams(text: '오늘의 맛집: ${r.placeName}\n${r.roadAddressName.isNotEmpty ? r.roadAddressName : r.addressName}\n${r.placeUrl}'),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('공유하는 중 오류가 발생했습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.winner;
    final categoryLabel = categoryLabelFor(r.categoryName);
    final mapUrl = _buildMapUrl(r);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: OutlinedButton(onPressed: () => context.go('/'), child: const Text('다시하기')),
                  ),
                  const Text('오늘의 우승!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  const Text(
                    '당신의 완벽한\n한 끼를 찾았어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1a2a4a), height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('👑', style: TextStyle(fontSize: 26)),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -12),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            color: const Color(0xFF1E5C5C),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('WINNER', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                                Text(categoryLabel, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                                const SizedBox(height: 6),
                                const Text('🏆', style: TextStyle(fontSize: 40)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(winCountBadge(_winCount), style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(r.placeName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1a2a4a))),
                                const SizedBox(height: 4),
                                Text(
                                  r.roadAddressName.isNotEmpty ? r.roadAddressName : (r.addressName.isNotEmpty ? r.addressName : '오늘 당신을 위한 최고의 선택입니다.'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => launchUrl(Uri.parse(mapUrl), mode: LaunchMode.externalApplication),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: const Text('지도 보기 (Go Eat) 🗺️'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _handleShare,
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                            child: const Text('공유하기 (Share)'),
                          ),
                        ),
                        TextButton(onPressed: () => context.go('/'), child: const Text('홈으로', style: TextStyle(color: AppColors.textSecondary))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const FloatingContactButton(),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 40,
                gravity: 0.25,
                colors: const [Color(0xFFFF7F50), Color(0xFFF4D125), AppColors.gold, Color(0xFFFF4500), Colors.white, AppColors.primary],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

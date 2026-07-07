import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/restaurant.dart';
import '../../../shared/models/restaurant_category.dart';
import '../../../shared/services/restaurant_stats_service.dart';
import '../../../shared/services/restaurant_badge.dart';
import '../../../shared/widgets/kakao_webview.dart';
import '../application/decision_resume.dart';
import '../application/decision_session.dart';
import 'widgets/decision_timer_chip.dart';

class _MatchSnapshot {
  _MatchSnapshot(this.bracket, this.matchIdx, this.roundWinners, this.round);
  final List<Restaurant?> bracket;
  final int matchIdx;
  final List<Restaurant> roundWinners;
  final int round;
}

List<Restaurant?> _makeBracket(List<Restaurant> list) {
  final bracket = <Restaurant?>[...list]..shuffle(Random());
  if (bracket.length % 2 != 0) bracket.add(null);
  return bracket;
}

/// Port of app/tournament.tsx: single-elimination bracket with bye auto-advance.
class TournamentScreen extends StatefulWidget {
  const TournamentScreen({
    super.key,
    required this.restaurants,
    this.locationName = '',
  });

  final List<Restaurant> restaurants;
  final String locationName;

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  late List<Restaurant?> _bracket = _makeBracket(widget.restaurants);
  int _matchIdx = 0;
  List<Restaurant> _roundWinners = [];
  int _round = 1;
  String? _selectedSide; // 'left' | 'right'
  final List<_MatchSnapshot> _history = [];
  Map<String, int> _winCountMap = {};

  @override
  void initState() {
    super.initState();
    _loadWinCounts();
    DecisionResumeService.instance.saveTournamentSession(
      contenders: widget.restaurants,
      locationName: widget.locationName,
    );
  }

  Future<void> _loadWinCounts() async {
    if (widget.restaurants.isEmpty) return;
    final map = await RestaurantStatsService.instance.getWinCounts(
      widget.restaurants.map((r) => r.id).toList(),
    );
    if (mounted) setState(() => _winCountMap = map);
  }

  int get _totalMatches => _bracket.length ~/ 2;
  Restaurant? get _left =>
      _matchIdx * 2 < _bracket.length ? _bracket[_matchIdx * 2] : null;
  Restaurant? get _right =>
      _matchIdx * 2 + 1 < _bracket.length ? _bracket[_matchIdx * 2 + 1] : null;

  Restaurant? get _activeRestaurant => _selectedSide == 'left'
      ? _left
      : (_selectedSide == 'right' ? _right : null);

  String _getRoundName({int? total}) {
    total ??= _bracket.length;
    switch (total) {
      case 2:
        return '결승전';
      case 4:
        return '준결승';
      case 8:
        return '8강전';
      case 16:
        return '16강전';
      case 32:
        return '32강전';
      default:
        return '$total강전';
    }
  }

  void _pickWinner(Restaurant winner, {bool saveHistory = true}) {
    if (saveHistory) {
      _history.add(_MatchSnapshot(_bracket, _matchIdx, _roundWinners, _round));
    }

    final matchLeft = _left;
    final matchRight = _right;
    final loser = matchLeft?.id == winner.id ? matchRight : matchLeft;
    if (loser != null) RestaurantStatsService.instance.recordLoss(loser.id);

    var next = [..._roundWinners, winner];
    var nextIdx = _matchIdx + 1;

    while (nextIdx < _totalMatches) {
      final l = _bracket[nextIdx * 2];
      final r = _bracket[nextIdx * 2 + 1];
      if (l != null && r == null) {
        next = [...next, l];
        nextIdx++;
      } else if (l == null && r != null) {
        next = [...next, r];
        nextIdx++;
      } else {
        break;
      }
    }

    if (nextIdx >= _totalMatches) {
      if (next.length == 1) {
        RestaurantStatsService.instance.recordWin(next[0].id);
        DecisionSessionService.instance.recordStage('오늘의 픽', 1);
        DecisionResumeService.instance.clear();
        context.pushReplacement('/result', extra: {'restaurant': next[0]});
        return;
      }
      DecisionSessionService.instance.recordStage(
        _getRoundName(total: next.length),
        next.length,
      );
      DecisionResumeService.instance.saveTournamentSession(
        contenders: next,
        locationName: widget.locationName,
      );
      setState(() {
        _bracket = _makeBracket(next);
        _matchIdx = 0;
        _roundWinners = [];
        _round += 1;
        _selectedSide = null;
      });
    } else {
      setState(() {
        _matchIdx = nextIdx;
        _roundWinners = next;
        _selectedSide = null;
      });
    }
  }

  void _handleConfirm() {
    final winner = _selectedSide == 'left' ? _left : _right;
    if (winner != null) _pickWinner(winner);
  }

  void _handleGoBack() {
    if (_history.isNotEmpty) {
      final prev = _history.removeLast();
      setState(() {
        _bracket = prev.bracket;
        _matchIdx = prev.matchIdx;
        _roundWinners = prev.roundWinners;
        _round = prev.round;
        _selectedSide = null;
      });
    } else {
      context.pop();
    }
  }

  void _handleTodayPick() {
    final r = _activeRestaurant;
    if (r != null) {
      DecisionSessionService.instance.recordStage('오늘의 픽', 1);
      DecisionResumeService.instance.clear();
      context.push('/result', extra: {'restaurant': r});
    }
  }

  @override
  Widget build(BuildContext context) {
    final left = _left;
    final right = _right;
    if (left == null && right == null) return const SizedBox.shrink();

    final activeUrl = _activeRestaurant != null
        ? (_activeRestaurant!.placeUrl.isNotEmpty
              ? _activeRestaurant!.placeUrl
              : 'https://place.map.kakao.com/${_activeRestaurant!.id}')
        : null;

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.surfaceMuted),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _handleGoBack,
                    icon: const Icon(Icons.chevron_left, size: 26),
                  ),
                  Text(
                    '${_getRoundName()}  ${_matchIdx + 1} / $_totalMatches',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const DecisionTimerChip(),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: _totalMatches > 0 ? (_matchIdx + 1) / _totalMatches : 0,
              minHeight: 3,
              backgroundColor: const Color(0xFFE5E7EB),
              color: AppColors.primary,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Text(
                '세상에서 제일 힘든 선택이지? 하나만 골라.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        color: const Color(0xFFF0F0F0),
                        child: activeUrl != null
                            ? KakaoWebView(uri: activeUrl)
                            : const Center(
                                child: Text(
                                  '👆 카드를 선택하면\n맛집 정보가 표시돼요',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (_selectedSide != null && activeUrl != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: _handleTodayPick,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '⭐ 오늘의 픽!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (left != null) Expanded(child: _matchCard(left, 'left')),
                    const SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD1D5DB),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    if (right != null)
                      Expanded(child: _matchCard(right, 'right')),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.surfaceMuted)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleGoBack,
                      child: const Text('← 이전으로'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedSide == null ? null : _handleConfirm,
                      child: const Text('선택하기 →'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchCard(Restaurant r, String side) {
    final selected = _selectedSide == side;
    return GestureDetector(
      onTap: () => setState(() => _selectedSide = side),
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 3 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              categoryEmojiFor(r.categoryName),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 2),
            Text(
              categoryLabelFor(r.categoryName),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFF9CA3AF),
              ),
            ),
            Text(
              r.placeName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              winCountBadge(_winCountMap[r.id]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: selected
                    ? Colors.white.withValues(alpha: 0.75)
                    : const Color(0xFF6B7280),
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '✓ 선택됨',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Port of lib/firestore.ts's restaurants/{id} stats helpers.
/// All writes are best-effort (RN also treats them as fire-and-forget with a
/// silent console.warn on failure) so a missing/unconfigured Firebase project
/// never blocks the swipe/tournament/result flow.
class RestaurantStatsService {
  RestaurantStatsService._();
  static final instance = RestaurantStatsService._();

  CollectionReference<Map<String, dynamic>> get _restaurants =>
      FirebaseFirestore.instance.collection('restaurants');

  Future<int> getChoiceCount(String restaurantId) async {
    try {
      final snap = await _restaurants.doc(restaurantId).get();
      return (snap.data()?['choiceCount'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('[stats] getChoiceCount 실패: $e');
      return 0;
    }
  }

  /// 여러 식당의 winCount를 한 번에 조회 (토너먼트 화면 초기 로드용).
  Future<Map<String, int>> getWinCounts(List<String> restaurantIds) async {
    final result = <String, int>{};
    try {
      final snaps = await Future.wait(
        restaurantIds.map((id) => _restaurants.doc(id).get()),
      );
      for (var i = 0; i < restaurantIds.length; i++) {
        result[restaurantIds[i]] =
            (snaps[i].data()?['winCount'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('[stats] getWinCounts 실패: $e');
    }
    return result;
  }

  /// 토너먼트 최종 우승 — winCount++ 후 winRate 재계산 (transaction).
  Future<void> recordWin(String restaurantId) async {
    try {
      final ref = _restaurants.doc(restaurantId);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() ?? {};
        final newWinCount = ((data['winCount'] as num?)?.toInt() ?? 0) + 1;
        final loseCount = (data['loseCount'] as num?)?.toInt() ?? 0;
        final tournamentCount = (newWinCount + loseCount).clamp(1, 1 << 30);
        tx.set(ref, {
          'winCount': newWinCount,
          'winRate': newWinCount / tournamentCount,
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('[stats] recordWin 실패: $e');
    }
  }

  Future<void> recordLoss(String restaurantId) async {
    try {
      await _restaurants.doc(restaurantId).set({
        'loseCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[stats] recordLoss 실패: $e');
    }
  }

  Future<void> recordSwipeChoice(String restaurantId) async {
    try {
      await _restaurants.doc(restaurantId).set({
        'choiceCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[stats] recordSwipeChoice 실패: $e');
    }
  }

  Future<void> recordSwipePass(String restaurantId) async {
    try {
      await _restaurants.doc(restaurantId).set({
        'passCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[stats] recordSwipePass 실패: $e');
    }
  }
}

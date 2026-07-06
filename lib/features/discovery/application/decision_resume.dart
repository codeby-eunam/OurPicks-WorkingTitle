import 'dart:convert';

import '../../../core/storage/local_store.dart';
import '../../../shared/models/restaurant.dart';

enum ResumeMode { swipe, tournament }

/// 스와이프/토너먼트 중단 시점의 스냅샷. 홈 화면의 '이어하기' 배너가 이걸 읽는다.
class ResumableSession {
  const ResumableSession({
    required this.mode,
    required this.restaurants,
    required this.locationName,
    required this.savedAt,
    this.liked = const [],
  });

  final ResumeMode mode;
  final List<Restaurant> restaurants;
  final List<Restaurant> liked;
  final String locationName;
  final DateTime savedAt;
}

/// Phase 1 '결정 재개' 기능: 앱을 나갔다 와도 스와이프/토너먼트 진행 상황을
/// 로컬에 저장해두고 홈 화면에서 이어서 고를 수 있게 한다.
/// 토너먼트는 정확한 대진표 상태 대신 '아직 남아있는 후보' 목록만 보존하고,
/// 재개 시 그 후보들로 새 대진표를 짠다.
class DecisionResumeService {
  DecisionResumeService._();
  static final instance = DecisionResumeService._();

  static const _key = 'dangmatch_resume_session';
  static const _maxAge = Duration(hours: 6);

  Future<void> saveSwipeSession({
    required List<Restaurant> remaining,
    required List<Restaurant> liked,
    required String locationName,
  }) {
    if (remaining.isEmpty) return clear();
    return _save(
      ResumableSession(
        mode: ResumeMode.swipe,
        restaurants: remaining,
        liked: liked,
        locationName: locationName,
        savedAt: DateTime.now(),
      ),
    );
  }

  Future<void> saveTournamentSession({
    required List<Restaurant> contenders,
    required String locationName,
  }) {
    if (contenders.length < 2) return clear();
    return _save(
      ResumableSession(
        mode: ResumeMode.tournament,
        restaurants: contenders,
        locationName: locationName,
        savedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _save(ResumableSession session) async {
    final payload = {
      'mode': session.mode.name,
      'locationName': session.locationName,
      'savedAt': session.savedAt.toIso8601String(),
      'restaurants': session.restaurants.map((r) => r.toJson()).toList(),
      'liked': session.liked.map((r) => r.toJson()).toList(),
    };
    await LocalStore.instance.setString(_key, jsonEncode(payload));
  }

  Future<ResumableSession?> load() async {
    final raw = await LocalStore.instance.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt =
          DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
          DateTime.now();
      if (DateTime.now().difference(savedAt) > _maxAge) {
        await clear();
        return null;
      }
      final restaurants = (json['restaurants'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(Restaurant.fromJson)
          .toList();
      if (restaurants.length < 2) {
        await clear();
        return null;
      }
      final liked = (json['liked'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(Restaurant.fromJson)
          .toList();
      final mode = json['mode'] == 'tournament'
          ? ResumeMode.tournament
          : ResumeMode.swipe;
      return ResumableSession(
        mode: mode,
        restaurants: restaurants,
        liked: liked,
        locationName: json['locationName']?.toString() ?? '',
        savedAt: savedAt,
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() => LocalStore.instance.remove(_key);
}

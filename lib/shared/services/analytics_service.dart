import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Port of lib/analytics.ts: silent Firestore 'events' logging.
/// Failures are swallowed (RN does the same with a dev-only console.warn) so
/// analytics never blocks the swipe/tournament/result UX.
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  Future<void> _logEvent(String event, Map<String, dynamic> payload, {String? userId}) async {
    try {
      await FirebaseFirestore.instance.collection('events').add({
        'event': event,
        if (userId != null) 'userId': userId,
        ...payload,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Analytics] 로그 저장 실패: $event $e');
    }
  }

  void logFilterSelected(List<String> filters, String locationName, {String? userId}) {
    _logEvent('filter_selected', {'filters': filters, 'locationName': locationName}, userId: userId);
  }

  void logLocationSearched(String query, int resultCount, {String? selectedPlace, String? userId}) {
    _logEvent('location_searched', {
      'query': query,
      'resultCount': resultCount,
      if (selectedPlace != null) 'selectedPlace': selectedPlace,
    }, userId: userId);
  }

  void logCardViewed(
    String storeId,
    String storeName,
    String category,
    String locationName,
    int dwellTimeMs, {
    String? userId,
  }) {
    _logEvent('card_viewed', {
      'storeId': storeId,
      'storeName': storeName,
      'category': category,
      'locationName': locationName,
      'dwellTimeMs': dwellTimeMs,
    }, userId: userId);
  }

  /// mode: 'swipe' | 'tournament' | 'random'
  void logRestaurantSelected(
    String storeId,
    String storeName,
    String category,
    String mode,
    String locationName, {
    String? userId,
  }) {
    _logEvent('restaurant_selected', {
      'storeId': storeId,
      'storeName': storeName,
      'category': category,
      'mode': mode,
      'locationName': locationName,
    }, userId: userId);
  }

  /// level: 'unsure' | 'okay' | 'confident' | 'very_confident'
  void logChoiceConfidence(String storeId, String level, {String? userId}) {
    _logEvent('choice_confidence', {'storeId': storeId, 'level': level}, userId: userId);
  }

  void logTournamentWinner(
    String storeId,
    String storeName,
    int roundCount,
    String locationName, {
    String? userId,
  }) {
    _logEvent('tournament_winner', {
      'storeId': storeId,
      'storeName': storeName,
      'roundCount': roundCount,
      'locationName': locationName,
    }, userId: userId);
  }
}

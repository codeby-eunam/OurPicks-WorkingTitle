import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/restaurant.dart';

/// Talks to the existing backend's Kakao-backed endpoints, reused as-is from
/// the RN app (lib usage in app/mode-select.tsx, app/(tabs)/index.tsx).
class RestaurantApi {
  RestaurantApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// GET /api/kakao/nearby?lat=&lng=&radius=&category=&maxPages=
  Future<List<Restaurant>> fetchNearby({
    required double lat,
    required double lng,
    required String category,
    int radius = 3000,
    int maxPages = 3,
  }) async {
    try {
      final response = await _client.dio.get(
        '/api/kakao/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radius,
          'category': category,
          'maxPages': maxPages,
        },
      );

      final documents = (response.data['documents'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      return documents.map(Restaurant.fromJson).toList();
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    } catch (_) {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }

  /// GET /api/kakao/search-location?query=
  Future<List<Restaurant>> searchLocation(String query) async {
    try {
      final response = await _client.dio.get(
        '/api/kakao/search-location',
        queryParameters: {'query': query},
      );

      final documents = (response.data['documents'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      return documents.map(Restaurant.fromJson).toList();
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    } catch (_) {
      throw Exception('잘못된 응답 형식입니다.');
    }
  }

  /// GET /api/kakao/place-photo?id= — Kakao Local API returns no photo, so
  /// this reads it lazily (og:image scrape) for one card at a time instead
  /// of eagerly for a whole result list.
  Future<String> fetchPlacePhoto(String id) async {
    try {
      final response = await _client.dio.get(
        '/api/kakao/place-photo',
        queryParameters: {'id': id},
      );
      return response.data['photo_url']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return '서버 오류 (${e.response?.statusCode ?? '?'})';
  }
}

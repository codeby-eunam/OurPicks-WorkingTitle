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
  }

  /// GET /api/kakao/search-location?query=
  Future<List<Restaurant>> searchLocation(String query) async {
    final response = await _client.dio.get(
      '/api/kakao/search-location',
      queryParameters: {'query': query},
    );

    final documents = (response.data['documents'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return documents.map(Restaurant.fromJson).toList();
  }
}

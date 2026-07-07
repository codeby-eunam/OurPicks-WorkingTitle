import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/restaurant.dart';
import '../../../shared/services/restaurant_api.dart';

final restaurantApiProvider = Provider<RestaurantApi>((ref) => RestaurantApi());

class NearbyQuery {
  const NearbyQuery({
    required this.lat,
    required this.lng,
    this.category = '전체',
  });
  final double lat;
  final double lng;
  final String category;

  @override
  bool operator ==(Object other) =>
      other is NearbyQuery &&
      other.lat == lat &&
      other.lng == lng &&
      other.category == category;

  @override
  int get hashCode => Object.hash(lat, lng, category);
}

final nearbyRestaurantsProvider =
    FutureProvider.family<List<Restaurant>, NearbyQuery>((ref, query) async {
      final api = ref.watch(restaurantApiProvider);
      return api.fetchNearby(
        lat: query.lat,
        lng: query.lng,
        category: query.category,
      );
    });

/// Mirrors the RN `Restaurant` type, sourced from Kakao Local API responses
/// via the backend's /api/kakao/nearby and /api/kakao/search-location.
class Restaurant {
  const Restaurant({
    required this.id,
    required this.placeName,
    required this.categoryName,
    this.addressName = '',
    this.roadAddressName = '',
    this.phone = '',
    required this.x,
    required this.y,
    this.distance = '',
    this.placeUrl = '',
    this.naverUrl,
  });

  final String id;
  final String placeName;
  final String categoryName;
  final String addressName;
  final String roadAddressName;
  final String phone;
  final String x; // longitude
  final String y; // latitude
  final String distance;
  final String placeUrl;
  final String? naverUrl;

  double get lat => double.tryParse(y) ?? 0;
  double get lng => double.tryParse(x) ?? 0;

  /// Top-level category derived from "한식 > 음식점" style Kakao category_name.
  String get topCategory {
    final first = categoryName.split('>').first.trim();
    return first.isEmpty ? '기타' : first;
  }

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id']?.toString() ?? '',
      placeName: json['place_name']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      addressName: json['address_name']?.toString() ?? '',
      roadAddressName: json['road_address_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      x: json['x']?.toString() ?? '0',
      y: json['y']?.toString() ?? '0',
      distance: json['distance']?.toString() ?? '',
      placeUrl: json['place_url']?.toString() ?? '',
      naverUrl: json['naver_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'place_name': placeName,
      'category_name': categoryName,
      'address_name': addressName,
      'road_address_name': roadAddressName,
      'phone': phone,
      'x': x,
      'y': y,
      'distance': distance,
      'place_url': placeUrl,
      if (naverUrl != null) 'naver_url': naverUrl,
    };
  }
}

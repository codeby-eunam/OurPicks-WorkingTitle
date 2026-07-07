import '../../core/network/api_client.dart';
import 'restaurant.dart';
import 'restaurant_category.dart';

/// Port of context/LibraryContext.tsx's `Place`/`ListItem` types (보관함 항목).
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryName,
    required this.address,
    required this.image,
    required this.placeUrl,
  });

  final String id;
  final String name;

  /// '식당' | '카페'
  final String category;
  final String categoryName;
  final String address;
  final String image;
  final String placeUrl;

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '식당',
      categoryName: json['categoryName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      placeUrl: json['placeUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'categoryName': categoryName,
      'address': address,
      'image': image,
      'placeUrl': placeUrl,
    };
  }
}

class ListItem {
  const ListItem({
    required this.id,
    required this.title,
    required this.count,
    required this.type,
    required this.icon,
    required this.images,
    required this.places,
    required this.isPublic,
    this.shareToken,
    this.ownerUid,
    this.ownerUserId,
  });

  final String id;
  final String title;
  final int count;

  /// '식당' | '카페'
  final String type;
  final String icon;
  final List<String> images;
  final List<Place> places;
  final bool isPublic;
  final String? shareToken;
  final String? ownerUid;
  final String? ownerUserId;

  ListItem copyWith({
    String? title,
    int? count,
    String? type,
    String? icon,
    List<String>? images,
    List<Place>? places,
    bool? isPublic,
  }) {
    return ListItem(
      id: id,
      title: title ?? this.title,
      count: count ?? this.count,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      images: images ?? this.images,
      places: places ?? this.places,
      isPublic: isPublic ?? this.isPublic,
      shareToken: shareToken,
      ownerUid: ownerUid,
      ownerUserId: ownerUserId,
    );
  }

  factory ListItem.fromServerJson(Map<String, dynamic> raw) {
    final rawRestaurants = (raw['restaurants'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final places = rawRestaurants.map((r) {
      final category = r['category']?.toString() ?? '';
      final images = (r['images'] as List?)?.cast<String>() ?? const [];
      return Place(
        id: r['id']?.toString() ?? '',
        name: r['name']?.toString() ?? '',
        category: category.contains('카페') ? '카페' : '식당',
        categoryName: category,
        address: r['address']?.toString() ?? '',
        image: images.isNotEmpty
            ? images.first
            : 'https://picsum.photos/seed/${r['id']}/200/200',
        placeUrl: r['kakaoUrl']?.toString() ?? '',
      );
    }).toList();

    final cafeCount = places.where((p) => p.category == '카페').length;
    final type = cafeCount > places.length / 2 ? '카페' : '식당';

    return ListItem(
      id: raw['id']?.toString() ?? '',
      title: raw['title']?.toString() ?? '',
      count: places.length,
      type: type,
      icon: type == '카페' ? 'local-cafe' : 'restaurant',
      images: rebuildImages(places),
      places: places,
      isPublic: raw['isPublic'] == true,
      shareToken: raw['shareToken']?.toString(),
      ownerUid: raw['ownerUid']?.toString(),
      ownerUserId: raw['ownerUserId']?.toString(),
    );
  }
}

/// Port of app/(tabs)/library.tsx's search-result → Place mapping.
Place placeFromRestaurant(Restaurant r) {
  final categoryShort = categoryLabelFor(r.categoryName);
  final isCafe = r.categoryName.contains('카페');
  return Place(
    id: r.id,
    name: r.placeName,
    category: isCafe ? '카페' : '식당',
    categoryName: categoryShort.isEmpty ? '기타' : categoryShort,
    address: r.roadAddressName.isNotEmpty ? r.roadAddressName : r.addressName,
    image: r.photoUrl.isNotEmpty
        ? '$kApiBase${r.photoUrl}'
        : 'https://picsum.photos/seed/${r.id}/200/200',
    placeUrl: r.placeUrl,
  );
}

/// context/LibraryContext.tsx의 rebuildImages: 최대 4개, 부족하면 첫 이미지로 채움.
List<String> rebuildImages(List<Place> places) {
  final raw = places.take(4).map((p) => p.image).toList();
  final fallback = raw.isNotEmpty
      ? raw.first
      : 'https://picsum.photos/seed/default/200/200';
  while (raw.length < 4) {
    raw.add(fallback);
  }
  return raw;
}

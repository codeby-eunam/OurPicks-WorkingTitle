import '../../../core/network/api_client.dart';
import '../../../shared/models/place.dart';

Map<String, dynamic> _placeToRestaurantPayload(Place p) {
  return {
    'id': p.id,
    'name': p.name,
    'category': p.categoryName.isNotEmpty ? p.categoryName : p.category,
    'address': p.address,
    'phone': '',
    'lat': 0,
    'lng': 0,
    if (p.placeUrl.isNotEmpty) 'kakaoUrl': p.placeUrl,
    'images': [p.image],
  };
}

/// Port of context/LibraryContext.tsx's apiFetch calls against /api/lists*.
class LibraryApi {
  LibraryApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// GET /api/lists/public — 탐색 탭용 공개 보관함 목록.
  Future<List<ListItem>> fetchPublicLists() async {
    final response = await _client.dio.get('/api/lists/public');
    final lists = (response.data['lists'] as List? ?? []).cast<Map<String, dynamic>>();
    return lists.map(ListItem.fromServerJson).toList();
  }

  /// GET /api/share/{shareToken} — 공유 링크로 열람하는 읽기 전용 보관함.
  Future<ListItem?> fetchShared(String shareToken) async {
    final response = await _client.dio.get('/api/share/$shareToken');
    final data = response.data as Map<String, dynamic>?;
    if (data == null || data['id'] == null) return null;
    return ListItem.fromServerJson(data);
  }

  Future<List<ListItem>> fetchLists(String uid) async {
    final response = await _client.dio.get('/api/lists', queryParameters: {'uid': uid});
    final lists = (response.data['lists'] as List? ?? []).cast<Map<String, dynamic>>();
    return lists.map(ListItem.fromServerJson).toList();
  }

  Future<ListItem> createList({
    required String uid,
    required String title,
    required List<Place> places,
  }) async {
    final response = await _client.dio.post(
      '/api/lists',
      data: {
        'uid': uid,
        'title': title,
        'ownerUid': uid,
        'places': places
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'categoryName': p.categoryName,
                  'address': p.address,
                  'image': p.image,
                  'placeUrl': p.placeUrl,
                })
            .toList(),
      },
    );
    return ListItem.fromServerJson(response.data['list'] as Map<String, dynamic>);
  }

  Future<void> addRestaurant(String uid, String listId, Place place) {
    return _client.dio.patch(
      '/api/lists/$listId/restaurants',
      data: {'uid': uid, 'action': 'add', 'restaurant': _placeToRestaurantPayload(place)},
    );
  }

  Future<void> removeRestaurant(String uid, String listId, String placeId) {
    return _client.dio.patch(
      '/api/lists/$listId/restaurants',
      data: {'uid': uid, 'action': 'remove', 'restaurantId': placeId},
    );
  }

  Future<void> renameList(String uid, String listId, String title) {
    return _client.dio.patch('/api/lists/$listId/title', data: {'uid': uid, 'title': title});
  }

  Future<void> setVisibility(String uid, String listId, bool isPublic) {
    return _client.dio.patch('/api/lists/$listId/visibility', data: {'uid': uid, 'isPublic': isPublic});
  }

  Future<void> deleteList(String uid, String listId) {
    return _client.dio.delete('/api/lists/$listId', data: {'uid': uid});
  }
}

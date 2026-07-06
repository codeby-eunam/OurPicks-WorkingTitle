import '../../../core/network/api_client.dart';

class UserLogEntry {
  const UserLogEntry({required this.id, required this.restaurantId, required this.restaurantName, required this.selectedAt, this.reviewed = false});

  final String id;
  final String restaurantId;
  final String restaurantName;
  final dynamic selectedAt; // Firestore Timestamp map, ISO string, or epoch millis
  final bool reviewed;

  factory UserLogEntry.fromJson(Map<String, dynamic> json) {
    return UserLogEntry(
      id: json['id']?.toString() ?? '',
      restaurantId: json['restaurantId']?.toString() ?? '',
      restaurantName: json['restaurantName']?.toString() ?? '',
      selectedAt: json['selectedAt'],
      reviewed: json['reviewed'] == true,
    );
  }

  DateTime get selectedAtDate {
    final value = selectedAt;
    if (value is Map) {
      final secs = value['seconds'] ?? value['_seconds'];
      if (secs != null) return DateTime.fromMillisecondsSinceEpoch((secs as num).toInt() * 1000);
      return DateTime.now();
    }
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

/// Port of app/my-selections.tsx + app/review.tsx API calls.
class UserLogApi {
  UserLogApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<UserLogEntry>> fetchLogs(String userId) async {
    final response = await _client.dio.get('/api/userlog', queryParameters: {'userId': userId});
    final logs = (response.data['logs'] as List? ?? []).cast<Map<String, dynamic>>();
    return logs.map(UserLogEntry.fromJson).toList();
  }

  Future<void> submitReview({
    required String userId,
    required String restaurantId,
    required String restaurantName,
    required String comment,
    int? peopleCount,
    int? totalPrice,
    int? pricePerPerson,
  }) {
    return _client.dio.post('/api/reviews', data: {
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'comment': comment,
      'peopleCount': peopleCount,
      'totalPrice': totalPrice,
      'pricePerPerson': pricePerPerson,
    });
  }
}

import '../../core/network/api_client.dart';

/// POST /api/feedback/notify — reused as-is from components/floating-contact-button.tsx.
class FeedbackApi {
  FeedbackApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<bool> sendFeedback({
    required String message,
    String? nickname,
    String? uid,
  }) async {
    final response = await _client.dio.post(
      '/api/feedback/notify',
      data: {
        'type': 'feedback',
        'message': message,
        'nickname': nickname,
        'uid': uid,
      },
    );
    return response.data['ok'] == true;
  }
}

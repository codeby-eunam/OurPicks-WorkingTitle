import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/app_user.dart';

/// Talks to /api/auth/* on the existing backend, reused as-is (context/UserContext.tsx).
class UserApi {
  UserApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// POST /api/auth/setup-profile
  Future<Map<String, dynamic>> setupProfile({
    required String userId,
    required String nickname,
    required String kakaoId,
    required AuthProvider provider,
  }) async {
    try {
      final response = await _client.dio.post(
        '/api/auth/setup-profile',
        data: {
          provider.idField: kakaoId,
          'provider': provider.name,
          'userId': userId,
          'nickname': nickname,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  /// PATCH /api/auth/update-profile
  Future<void> updateNickname({
    required String kakaoId,
    required AuthProvider provider,
    required String nickname,
  }) async {
    try {
      await _client.dio.patch(
        '/api/auth/update-profile',
        data: {provider.idField: kakaoId, 'nickname': nickname},
      );
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  /// GET /api/auth/check-userid?userId=
  Future<bool> checkUserIdAvailable(String userId) async {
    try {
      final response = await _client.dio.get(
        '/api/auth/check-userid',
        queryParameters: {'userId': userId},
      );
      return response.data['available'] == true;
    } catch (_) {
      return true;
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (data is Map && data['message'] is String)
      return data['message'] as String;
    return '서버 오류 (${e.response?.statusCode ?? '?'})';
  }
}

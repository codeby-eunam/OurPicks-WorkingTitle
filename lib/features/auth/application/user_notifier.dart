import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_store.dart';
import '../../../shared/models/app_user.dart';
import '../data/user_api.dart';
import 'user_state.dart';

/// dangmatch://auth/callback — matches the RN app's scheme (app.json) and
/// the CallbackActivity/CFBundleURLTypes registered for it.
const _kCallbackScheme = 'dangmatch';
const _kRedirectUri = '$_kCallbackScheme://auth/callback';

/// Port of context/UserContext.tsx as a Riverpod Notifier.
class UserNotifier extends Notifier<UserState> {
  final _api = UserApi();

  /// Resolves once the AsyncStorage-equivalent restore-on-start has finished.
  /// Await this before deciding whether to redirect to /landing.
  late final Future<void> ready;

  @override
  UserState build() {
    ready = _restore();
    return const UserState();
  }

  Future<void> _restore() async {
    final userJson = await LocalStore.instance.getString(LocalStore.keyUser);
    final providerName = await LocalStore.instance.getString(LocalStore.keyLastProvider);

    AppUser? user;
    if (userJson != null) {
      try {
        user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        await LocalStore.instance.remove(LocalStore.keyUser);
      }
    }

    state = state.copyWith(
      user: user,
      clearUser: user == null,
      hasSeenLanding: user != null ? true : state.hasSeenLanding,
      lastUsedProvider: providerName != null ? AuthProvider.fromName(providerName) : null,
      initialized: true,
    );
  }

  void setHasSeenLanding() {
    state = state.copyWith(hasSeenLanding: true);
  }

  /// context/UserContext.tsx의 processOAuthParams 1:1 이식.
  OAuthResult processOAuthParams(Map<String, String> params) {
    final error = params['error'];
    if (error != null) {
      throw Exception('[백엔드] ${Uri.decodeComponent(error)}');
    }

    AuthProvider provider;
    String socialId;
    if (params['kakaoId'] != null) {
      provider = AuthProvider.kakao;
      socialId = params['kakaoId']!;
    } else if (params['naverId'] != null) {
      provider = AuthProvider.naver;
      socialId = params['naverId']!;
    } else if (params['googleId'] != null) {
      provider = AuthProvider.google;
      socialId = params['googleId']!;
    } else {
      throw Exception('소셜 로그인 정보를 찾을 수 없습니다.');
    }

    final isNewUser = params['isNewUser'] == 'true';
    final nickname = params['nickname'] ?? '';
    final profileImage = (params['profileImage']?.isNotEmpty ?? false) ? params['profileImage'] : null;
    final userId = params['userId'];
    final joinOrder = int.tryParse(params['joinOrder'] ?? '9999') ?? 9999;
    final badgesParam = params['badges'] ?? '';

    final badges = <String>[];
    if (badgesParam.contains('초기멤버') || joinOrder <= 1000) {
      badges.add('초기멤버');
    }

    if (isNewUser || userId == null || userId.isEmpty) {
      state = state.copyWith(
        pendingLogin: PendingLogin(
          kakaoId: socialId,
          nickname: nickname,
          profileImage: profileImage,
          provider: provider,
        ),
      );
      return OAuthResult(
        needsSetup: true,
        kakaoId: socialId,
        profileImage: profileImage,
        provider: provider,
      );
    }

    final user = AppUser(
      kakaoId: socialId,
      provider: provider,
      userId: userId,
      nickname: nickname,
      profileImage: profileImage,
      joinOrder: joinOrder,
      badges: badges,
      createdAt: params['createdAt'] ?? DateTime.now().toIso8601String(),
    );
    state = state.copyWith(user: user, hasSeenLanding: true);
    _persistUser(user);
    return OAuthResult(needsSetup: false, kakaoId: socialId, provider: provider);
  }

  /// {API_BASE}/api/auth/{provider}?redirect_uri=dangmatch://auth/callback 를 열고
  /// flutter_web_auth_2로 콜백을 캡처한다 (RN의 expo-web-browser openAuthSessionAsync 대응).
  /// 사용자가 인증을 취소하면 null을 반환한다.
  Future<OAuthResult?> loginWith(AuthProvider provider) async {
    final url = Uri.parse('$kApiBase/api/auth/${provider.name}').replace(
      queryParameters: {'redirect_uri': _kRedirectUri},
    );

    late final String resultUrl;
    try {
      resultUrl = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: _kCallbackScheme,
      );
    } catch (_) {
      return null; // 사용자가 취소함
    }

    final params = Uri.parse(resultUrl).queryParameters;
    final result = processOAuthParams(params);

    state = state.copyWith(lastUsedProvider: provider);
    await LocalStore.instance.setString(LocalStore.keyLastProvider, provider.name);

    return result;
  }

  Future<void> setupProfile({
    required String userId,
    required String nickname,
    required String kakaoId,
    required AuthProvider provider,
    String? profileImage,
  }) async {
    final data = await _api.setupProfile(
      userId: userId,
      nickname: nickname,
      kakaoId: kakaoId,
      provider: provider,
    );

    final joinOrder = (data['joinOrder'] as num?)?.toInt() ?? 9999;
    final badges = joinOrder <= 1000 ? ['초기멤버'] : <String>[];

    final user = AppUser(
      kakaoId: kakaoId,
      provider: provider,
      userId: userId,
      nickname: nickname,
      profileImage: profileImage,
      joinOrder: joinOrder,
      badges: badges,
      createdAt: data['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );

    state = state.copyWith(user: user, hasSeenLanding: true, clearPendingLogin: true);
    await _persistUser(user);
  }

  Future<void> updateNickname(String nickname) async {
    final user = state.user;
    if (user == null) throw Exception('로그인이 필요합니다.');

    await _api.updateNickname(kakaoId: user.kakaoId, provider: user.provider, nickname: nickname);

    final updated = user.copyWith(nickname: nickname);
    state = state.copyWith(user: updated);
    await _persistUser(updated);
  }

  Future<bool> checkUserIdAvailable(String userId) => _api.checkUserIdAvailable(userId);

  Future<void> logout() async {
    state = state.copyWith(clearUser: true);
    await LocalStore.instance.remove(LocalStore.keyUser);
  }

  Future<void> _persistUser(AppUser user) {
    return LocalStore.instance.setString(LocalStore.keyUser, jsonEncode(user.toJson()));
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(UserNotifier.new);

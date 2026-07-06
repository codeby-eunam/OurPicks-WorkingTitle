/// Mirrors context/UserContext.tsx's `Provider`/`User` types.
enum AuthProvider {
  kakao,
  naver,
  google;

  String get idField => switch (this) {
        AuthProvider.naver => 'naverId',
        AuthProvider.google => 'googleId',
        AuthProvider.kakao => 'kakaoId',
      };

  static AuthProvider fromName(String value) {
    return AuthProvider.values.firstWhere(
      (p) => p.name == value,
      orElse: () => AuthProvider.kakao,
    );
  }
}

class AppUser {
  const AppUser({
    required this.kakaoId,
    required this.provider,
    required this.userId,
    required this.nickname,
    this.profileImage,
    required this.joinOrder,
    this.badges = const [],
    required this.createdAt,
  });

  /// Social provider's user id (kakao/naver/google 공통 필드명은 여전히 kakaoId).
  final String kakaoId;
  final AuthProvider provider;
  final String userId;
  final String nickname;
  final String? profileImage;
  final int joinOrder;
  final List<String> badges;
  final String createdAt;

  AppUser copyWith({String? nickname}) {
    return AppUser(
      kakaoId: kakaoId,
      provider: provider,
      userId: userId,
      nickname: nickname ?? this.nickname,
      profileImage: profileImage,
      joinOrder: joinOrder,
      badges: badges,
      createdAt: createdAt,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      kakaoId: json['kakaoId']?.toString() ?? '',
      provider: AuthProvider.fromName(json['provider']?.toString() ?? 'kakao'),
      userId: json['userId']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      joinOrder: (json['joinOrder'] as num?)?.toInt() ?? 9999,
      badges: (json['badges'] as List? ?? []).map((e) => e.toString()).toList(),
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kakaoId': kakaoId,
      'provider': provider.name,
      'userId': userId,
      'nickname': nickname,
      if (profileImage != null) 'profileImage': profileImage,
      'joinOrder': joinOrder,
      'badges': badges,
      'createdAt': createdAt,
    };
  }
}

/// context/UserContext.tsx의 pendingKakaoLogin 대응 (신규 유저의 setup-profile 진입 전 임시 상태).
class PendingLogin {
  const PendingLogin({
    required this.kakaoId,
    required this.nickname,
    this.profileImage,
    required this.provider,
  });

  final String kakaoId;
  final String nickname;
  final String? profileImage;
  final AuthProvider provider;
}

/// context/UserContext.tsx의 OAuthResult 대응.
class OAuthResult {
  const OAuthResult({
    required this.needsSetup,
    required this.kakaoId,
    this.profileImage,
    required this.provider,
  });

  final bool needsSetup;
  final String kakaoId;
  final String? profileImage;
  final AuthProvider provider;
}

import 'package:flutter/material.dart';

/// Design system palette per the ourpicks product brief (Notion/Apple-inspired).
class AppColors {
  AppColors._();

  static const primary = Color(0xFF8B3A2A); // 딥 테라코타, 주 CTA
  static const secondary = Color(0xFF1E7874); // 토너먼트/보관함 액션 (보조 액센트, 브리프 범위 밖)
  static const kakaoYellow = Color(0xFFFEE500);
  static const pwaTeal = Color(0xFF006D77);
  static const pwaBackground = Color(0xFFEDF6F9);

  static const background = Color(0xFFF5F3EE); // 웜 오프화이트 페이지 배경
  static const surface = Color(0xFFFFFFFF); // 카드 서피스
  static const surfaceMuted = Color(0xFFEFEBE3); // 배경보다 살짝 어두운 웜 뉴트럴 (칩/구분 영역)
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const textMuted =
      textSecondary; // 별칭: 기존 코드에서 textMuted로 참조되는 곳들도 동일 톤 사용
  static const error = Color(0xFFEF4444);
  static const gold = Color(0xFFFFD700);

  /// 그림자 대신 면 구분에 쓰는 보더 (0.5px, AppRadius.hairline 참고).
  static const border = Color(0xFFE5DDD0);
}

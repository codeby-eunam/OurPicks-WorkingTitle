import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Design system palette per the ourpicks product brief (Notion/Apple-inspired).
///
/// Palette-driven fields are mutable so [apply] can swap the active theme
/// (A/B/C, see 설정 > 테마) at runtime — see ThemeNotifier.
class AppColors {
  AppColors._();

  static Color primary = AppPalettes.b.primary; // 딥 테라코타, 주 CTA
  static Color secondary = AppPalettes.b.secondary; // 토너먼트/보관함 액션 (보조 액센트, 브리프 범위 밖)
  static const kakaoYellow = Color(0xFFFEE500);
  static const pwaTeal = Color(0xFF006D77);
  static const pwaBackground = Color(0xFFEDF6F9);

  static Color background = AppPalettes.b.background; // 웜 오프화이트 페이지 배경
  static Color surface = AppPalettes.b.surface; // 카드 서피스
  static Color surfaceMuted = AppPalettes.b.surfaceMuted; // 배경보다 살짝 어두운 웜 뉴트럴 (칩/구분 영역)
  static Color textPrimary = AppPalettes.b.textPrimary;
  static Color textSecondary = AppPalettes.b.textSecondary;
  static Color get textMuted => textSecondary;
  static const error = Color(0xFFEF4444);
  static const gold = Color(0xFFFFD700);

  /// 그림자 대신 면 구분에 쓰는 보더 (0.5px, AppRadius.hairline 참고).
  static Color border = AppPalettes.b.border;

  static void apply(ThemePalette palette) {
    primary = palette.primary;
    secondary = palette.secondary;
    background = palette.background;
    surface = palette.surface;
    surfaceMuted = palette.surfaceMuted;
    textPrimary = palette.textPrimary;
    textSecondary = palette.textSecondary;
    border = palette.border;
  }
}

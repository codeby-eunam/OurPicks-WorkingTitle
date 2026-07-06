import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Component rules per the ourpicks 브리프: 본문은 400, 헤딩/버튼은 500,
/// 헤딩에는 -0.02em 자간(letterSpacing)을 적용한다.
class AppTypography {
  AppTypography._();

  static const FontWeight body = FontWeight.w400;
  static const FontWeight emphasis = FontWeight.w500;

  /// -0.02em → 로직셀 픽셀 letterSpacing으로 환산 (Flutter는 em 단위를 지원하지 않음).
  static double headingLetterSpacing(double fontSize) => fontSize * -0.02;

  static TextStyle heading(
    double fontSize, {
    Color color = AppColors.textPrimary,
    FontWeight weight = emphasis,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      letterSpacing: headingLetterSpacing(fontSize),
      color: color,
    );
  }

  static TextStyle bodyStyle(
    double fontSize, {
    Color color = AppColors.textPrimary,
  }) {
    return TextStyle(fontSize: fontSize, fontWeight: body, color: color);
  }
}

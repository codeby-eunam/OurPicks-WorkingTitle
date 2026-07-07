import 'package:flutter/material.dart';

enum ThemePaletteId { a, b, c }

/// One of the three theme directions under review (design 브랜치 비교용).
class ThemePalette {
  const ThemePalette({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  final ThemePaletteId id;
  final String labelKo;
  final String labelEn;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  String label(Locale locale) => locale.languageCode == 'ko' ? labelKo : labelEn;
}

class AppPalettes {
  AppPalettes._();

  /// A — 번트 오렌지: 오렌지 채도를 낮춘 방향, 음식 사진과 가장 잘 어울림.
  static const a = ThemePalette(
    id: ThemePaletteId.a,
    labelKo: '번트 오렌지',
    labelEn: 'Burnt Orange',
    primary: Color(0xFFB5652D),
    secondary: Color(0xFF1E7874),
    background: Color(0xFFF7F5F1),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEFEBE3),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6B),
    border: Color(0xFFE5DDD0),
  );

  /// B — 딥 테라코타: 현재 앱 기본 테마 (절충안).
  static const b = ThemePalette(
    id: ThemePaletteId.b,
    labelKo: '딥 테라코타',
    labelEn: 'Deep Terracotta',
    primary: Color(0xFF8B3A2A),
    secondary: Color(0xFF1E7874),
    background: Color(0xFFF5F3EE),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEFEBE3),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6B),
    border: Color(0xFFE5DDD0),
  );

  /// C — 딥그린 + 오프화이트: 가장 단정/세련되지만 초록이 배경과 싸울 수 있음.
  static const c = ThemePalette(
    id: ThemePaletteId.c,
    labelKo: '딥그린 + 오프화이트',
    labelEn: 'Deep Green + Off-White',
    primary: Color(0xFF1F3D2B),
    secondary: Color(0xFF1E7874),
    background: Color(0xFFF4F3EF),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE9E7E1),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6B),
    border: Color(0xFFE0DED8),
  );

  static const all = [a, b, c];

  static ThemePalette byId(ThemePaletteId id) {
    return all.firstWhere((p) => p.id == id, orElse: () => b);
  }
}

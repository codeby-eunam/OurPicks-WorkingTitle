import 'package:flutter/material.dart';

/// Phase 1 design system: 모든 모서리 반경은 이 토큰만 사용한다.
/// 그림자는 사용하지 않고(플랫), 면 구분은 배경색/보더로만 한다.
class AppRadius {
  AppRadius._();

  /// 칩, 인풋 내부 요소 등 소형 요소.
  static const double sm = 8;

  /// 버튼, 인풋 필드.
  static const double md = 10;

  /// 카드, 리스트 컨테이너.
  static const double lg = 16;

  /// 바텀시트 상단, 대형 서피스.
  static const double xl = 24;

  /// 완전한 알약형 (토글, 배지, 라운드 버튼).
  static const double pill = 999;

  /// Apple 스타일 헤어라인 보더 두께.
  static const double hairline = 0.5;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get pillAll => BorderRadius.circular(pill);

  /// 바텀시트 공통 셰이프.
  static const RoundedRectangleBorder sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(xl)),
  );
}

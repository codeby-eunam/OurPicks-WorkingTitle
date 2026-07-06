import 'dart:math';

/// Port of lib/restaurantBadge.ts: win_count 기반 맛집 배지 텍스트 생성.
final _hotTemplates = <String Function(int count)>[
  (count) => '🔥 $count명이 선택한 맛집',
  (count) => '🥇 $count번 우승한 가게',
];

final _knownTemplates = <String Function()>[
  () => '👍 사람들이 많이 고른 맛집',
  () => '🍽️ 검증된 맛집',
];

final _newTemplates = <String Function()>[
  () => '✨ 새로운 후보',
  () => '🆕 도전자',
];

final _random = Random();

T _pickRandom<T>(List<T> list) => list[_random.nextInt(list.length)];

/// win_count > 20 → hot, > 5 → known, 그 외 → new.
String winCountBadge(int? winCount) {
  final count = winCount ?? 0;
  if (count > 20) return _pickRandom(_hotTemplates)(count);
  if (count > 5) return _pickRandom(_knownTemplates)();
  return _pickRandom(_newTemplates)();
}

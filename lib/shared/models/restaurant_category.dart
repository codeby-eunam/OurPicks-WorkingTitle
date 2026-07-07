/// Port of app/tournament.tsx's getCategoryEmoji / getCategoryLabel helpers.
String categoryEmojiFor(String rawCategoryName) {
  final cat = (rawCategoryName.split('>').lastOrNull ?? '')
      .trim()
      .toLowerCase();
  if (cat.contains('카페') || cat.contains('커피')) return '☕';
  if (cat.contains('한식')) return '🍚';
  if (cat.contains('일식') || cat.contains('초밥')) return '🍣';
  if (cat.contains('중식')) return '🥡';
  if (cat.contains('양식') || cat.contains('파스타')) return '🍝';
  if (cat.contains('치킨')) return '🍗';
  if (cat.contains('피자')) return '🍕';
  if (cat.contains('버거') || cat.contains('햄버거')) return '🍔';
  if (cat.contains('분식') || cat.contains('떡볶이')) return '🍢';
  if (cat.contains('고기') || cat.contains('삼겹')) return '🥩';
  return '🍽️';
}

String categoryLabelFor(String rawCategoryName) {
  final parts = rawCategoryName.split('>');
  final last = parts.isNotEmpty ? parts.last.trim() : '';
  return last.isEmpty ? '음식점' : last;
}

extension _LastOrNull<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}

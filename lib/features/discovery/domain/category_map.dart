/// Port of app/mode-select.tsx's CATEGORY_MAP.
const kCategoryMap = <String, List<String>>{
  'all': ['한식', '중식', '일식', '양식', '분식', '카페', '기타'],
  'korean': ['한식'],
  'japanese': ['일식'],
  'chinese': ['중식'],
  'western': ['양식'],
  'snack': ['분식'],
  'asian': ['기타'],
  'cafe': ['카페'],
};

const kAutoRadiusMeters = 3000;
const kSwipeThreshold = 16;

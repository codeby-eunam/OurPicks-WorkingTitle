/// Kakao Maps JS key. Doesn't exist in the RN project yet (it only used
/// server-side Kakao REST keys + a WebView pointed at place.map.kakao.com),
/// so it must be issued separately: Kakao Developers console → 앱 설정 →
/// 플랫폼 → Web 등록.
/// Pass at build/run time: flutter run --dart-define=KAKAO_JS_KEY=xxx
///
/// The Google Maps key is configured natively instead (it's read by the SDK
/// before Dart even starts) — see android/app/src/main/AndroidManifest.xml
/// and ios/Runner/AppDelegate.swift.
class MapConfig {
  MapConfig._();

  static const kakaoJsKey = String.fromEnvironment('KAKAO_JS_KEY');
}

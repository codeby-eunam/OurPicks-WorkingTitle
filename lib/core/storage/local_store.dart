import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences, mirroring the RN app's
/// AsyncStorage usage (context/UserContext.tsx, (tabs)/index.tsx).
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  static const keyUser = 'dangmatch_user';
  static const keyLastProvider = 'dangmatch_last_provider';
  static const keyHasSeenLanding = 'dangmatch_has_seen_landing';
  static const keyRecentLocationSearches = 'recentLocationSearches';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getString(String key) async => (await _instance()).getString(key);

  Future<void> setString(String key, String value) async {
    await (await _instance()).setString(key, value);
  }

  Future<bool?> getBool(String key) async => (await _instance()).getBool(key);

  Future<void> setBool(String key, bool value) async {
    await (await _instance()).setBool(key, value);
  }

  Future<List<String>?> getStringList(String key) async =>
      (await _instance()).getStringList(key);

  Future<void> setStringList(String key, List<String> value) async {
    await (await _instance()).setStringList(key, value);
  }

  Future<void> remove(String key) async {
    await (await _instance()).remove(key);
  }
}

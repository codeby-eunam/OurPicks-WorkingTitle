import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;

import 'app.dart';
import 'features/map/data/map_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (MapConfig.kakaoJsKey.isNotEmpty) {
    kakao.AuthRepository.initialize(appKey: MapConfig.kakaoJsKey);
  }

  // TODO(auth phase): call Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
  // once `flutterfire configure` has generated lib/firebase_options.dart against the
  // existing dangmatch-18049 project (needs the user's Google login, see plan).

  runApp(const ProviderScope(child: OurPicksApp()));
}

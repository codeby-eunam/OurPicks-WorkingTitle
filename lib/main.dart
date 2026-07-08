import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao;

import 'app.dart';
import 'features/map/data/map_config.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (MapConfig.kakaoJsKey.isNotEmpty) {
    kakao.AuthRepository.initialize(appKey: MapConfig.kakaoJsKey);
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: OurPicksApp()));
}

import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class OurPicksApp extends StatelessWidget {
  const OurPicksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '당맷치',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}

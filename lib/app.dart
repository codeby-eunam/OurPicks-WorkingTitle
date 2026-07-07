import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/application/locale_notifier.dart';
import 'features/settings/application/theme_notifier.dart';
import 'l10n/app_localizations.dart';

class OurPicksApp extends ConsumerWidget {
  const OurPicksApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider.select((s) => s.locale));
    final paletteId = ref.watch(themeProvider.select((s) => s.paletteId));

    // AppColors fields are mutated in place when the palette changes, so the
    // subtree needs a fresh key to force every screen to rebuild and re-read
    // the new values.
    return KeyedSubtree(
      key: ValueKey(paletteId),
      child: MaterialApp.router(
        title: '당맷치',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: appRouter,
      ),
    );
  }
}

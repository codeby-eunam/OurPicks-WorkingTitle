import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';

class ThemeState {
  const ThemeState({this.paletteId = ThemePaletteId.b});

  final ThemePaletteId paletteId;
}

/// Persists the selected color palette (A/B/C) and mutates [AppColors] so
/// the whole app re-reads the new values on next rebuild — see
/// OurPicksApp's KeyedSubtree in app.dart.
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    _restore();
    return const ThemeState();
  }

  Future<void> _restore() async {
    final saved = await LocalStore.instance.getString(
      LocalStore.keyThemePalette,
    );
    if (saved == null) return;
    final id = ThemePaletteId.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ThemePaletteId.b,
    );
    _apply(id);
  }

  Future<void> setPalette(ThemePaletteId id) async {
    await LocalStore.instance.setString(LocalStore.keyThemePalette, id.name);
    _apply(id);
  }

  void _apply(ThemePaletteId id) {
    AppColors.apply(AppPalettes.byId(id));
    state = ThemeState(paletteId: id);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

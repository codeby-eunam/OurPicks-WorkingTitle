import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_store.dart';

const supportedLocales = [Locale('ko'), Locale('en')];

class LocaleState {
  const LocaleState({this.locale = const Locale('ko'), this.hasChosen = false});

  final Locale locale;
  final bool hasChosen;

  LocaleState copyWith({Locale? locale, bool? hasChosen}) {
    return LocaleState(
      locale: locale ?? this.locale,
      hasChosen: hasChosen ?? this.hasChosen,
    );
  }
}

/// Persists the user's language choice (ko/en). [ready] resolves once the
/// saved preference has been restored — until then [hasChosen] is false,
/// which HomeScreen uses to decide whether to show the first-launch picker.
class LocaleNotifier extends Notifier<LocaleState> {
  late final Future<void> ready;

  @override
  LocaleState build() {
    ready = _restore();
    return const LocaleState();
  }

  Future<void> _restore() async {
    final code = await LocalStore.instance.getString(LocalStore.keyLocale);
    if (code != null) {
      state = state.copyWith(locale: Locale(code), hasChosen: true);
    }
  }

  Future<void> setLocale(String code) async {
    await LocalStore.instance.setString(LocalStore.keyLocale, code);
    state = state.copyWith(locale: Locale(code), hasChosen: true);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, LocaleState>(
  LocaleNotifier.new,
);

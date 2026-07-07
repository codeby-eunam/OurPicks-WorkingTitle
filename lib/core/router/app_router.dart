import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_callback_screen.dart';
import '../../features/auth/presentation/edit_profile_screen.dart';
import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/setup_profile_screen.dart';
import '../../features/discovery/presentation/mode_select_screen.dart';
import '../../features/discovery/presentation/restaurant_detail_screen.dart';
import '../../features/discovery/presentation/result_screen.dart';
import '../../features/discovery/presentation/swipe_screen.dart';
import '../../features/discovery/presentation/tournament_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/library/presentation/library_detail_screen.dart';
import '../../features/library/presentation/library_tab_screen.dart';
import '../../features/library/presentation/share_detail_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/my_selections/presentation/my_selections_screen.dart';
import '../../features/profile/presentation/profile_tab_screen.dart';
import '../../features/search/presentation/search_tab_screen.dart';
import '../../features/settings/presentation/language_picker_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/theme_picker_screen.dart';
import '../../shared/models/restaurant.dart';
import 'app_shell.dart';

/// RN 라우트 1:1 매핑 스켈레톤. 탭 4개는 StatefulShellRoute로 구성하고,
/// 그 외 화면은 전체 화면 push로 구성한다 (RN Stack과 동일 흐름).
/// 화면들은 task #3~#6에서 실제 구현으로 교체된다.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchTabScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryTabScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileTabScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) {
        final extra = state.extra as Map?;
        return MapScreen(
          initialLat: (extra?['lat'] as num?)?.toDouble(),
          initialLng: (extra?['lng'] as num?)?.toDouble(),
        );
      },
    ),
    GoRoute(
      path: '/landing',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/auth/callback',
      builder: (context, state) =>
          AuthCallbackScreen(queryParams: state.uri.queryParameters),
    ),
    GoRoute(
      path: '/setup-profile',
      builder: (context, state) {
        final extra = (state.extra as Map?) ?? const {};
        return SetupProfileScreen(
          kakaoId: extra['kakaoId']?.toString() ?? '',
          provider: extra['provider']?.toString() ?? 'kakao',
        );
      },
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/mode-select',
      builder: (context, state) {
        final extra = (state.extra as Map?) ?? const {};
        return ModeSelectScreen(
          lat: (extra['lat'] as num).toDouble(),
          lng: (extra['lng'] as num).toDouble(),
          locationName: extra['locationName']?.toString() ?? '',
          categoryFilters: extra['categoryFilters']?.toString() ?? 'all',
        );
      },
    ),
    GoRoute(
      path: '/swipe',
      builder: (context, state) {
        final extra = (state.extra as Map?) ?? const {};
        return SwipeScreen(
          restaurants: (extra['restaurants'] as List).cast<Restaurant>(),
          locationName: extra['locationName']?.toString() ?? '',
          initialLiked:
              (extra['liked'] as List?)?.cast<Restaurant>() ?? const [],
        );
      },
    ),
    GoRoute(
      path: '/tournament',
      builder: (context, state) {
        final extra = (state.extra as Map?) ?? const {};
        return TournamentScreen(
          restaurants: (extra['restaurants'] as List).cast<Restaurant>(),
          locationName: extra['locationName']?.toString() ?? '',
        );
      },
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final extra = (state.extra as Map?) ?? const {};
        return ResultScreen(winner: extra['restaurant'] as Restaurant);
      },
    ),
    GoRoute(
      path: '/restaurant-detail',
      builder: (context, state) {
        final extra = (state.extra as Map?) ?? const {};
        return RestaurantDetailScreen(
          placeId: extra['placeId']?.toString() ?? '',
          placeUrl: extra['placeUrl']?.toString(),
        );
      },
    ),
    GoRoute(
      path: '/library-detail',
      builder: (context, state) {
        final extra = (state.extra as Map?) ?? const {};
        return LibraryDetailScreen(listId: extra['listId']?.toString() ?? '');
      },
    ),
    GoRoute(
      path: '/share/:shareToken',
      builder: (context, state) =>
          ShareDetailScreen(shareToken: state.pathParameters['shareToken']!),
    ),
    GoRoute(
      path: '/my-selections',
      builder: (context, state) => const MySelectionsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/language-picker',
      builder: (context, state) {
        final isInitialPick = state.uri.queryParameters['initial'] != 'false';
        return LanguagePickerScreen(isInitialPick: isInitialPick);
      },
    ),
    GoRoute(
      path: '/theme-picker',
      builder: (context, state) => const ThemePickerScreen(),
    ),
  ],
);

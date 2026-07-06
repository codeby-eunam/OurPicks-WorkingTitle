import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Bottom-tab shell matching app/(tabs)/_layout.tsx: 홈 / 탐색 / 보관함 / 마이.
/// Tab bodies are placeholders until task #4/#5 replace them with the real
/// ported screens; this exists so navigation can be verified end-to-end now.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (label: '홈', icon: Icons.home_outlined),
    (label: '탐색', icon: Icons.search),
    (label: '보관함', icon: Icons.bookmark_border),
    (label: '마이', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: [
          for (final tab in _tabs)
            BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/social_login_required_view.dart';
import '../../auth/application/user_notifier.dart';
import '../../library/application/library_notifier.dart';

/// Port of app/(tabs)/profile.tsx: 마이페이지.
class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final t = AppLocalizations.of(context)!;

    if (!userState.isLoggedIn) {
      return Scaffold(
        body: SafeArea(
          child: SocialLoginRequiredView(
            emoji: '🔒',
            title: t.profileLoginRequiredTitle,
            description: t.profileLoginRequiredDescription,
          ),
        ),
      );
    }

    final user = userState.user!;
    final lists = ref.watch(libraryProvider).lists;
    final publicListCount = lists.where((l) => l.isPublic).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 48),
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0EB),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2.5,
                            ),
                          ),
                          child: const Center(
                            child: Text('🐻', style: TextStyle(fontSize: 38)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.nickname,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                user.userId,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        _StatItem(
                          label: t.profileStatLibrary,
                          value: '${lists.length}',
                        ),
                        const _StatDivider(),
                        _StatItem(
                          label: t.profileStatPublicList,
                          value: '$publicListCount',
                        ),
                      ],
                    ),
                  ),
                  _menuSection(context, t.profileSectionHistory, [
                    _MenuItem(
                      icon: '🍽️',
                      label: t.profileMenuMySelections,
                      onTap: () => context.push('/my-selections'),
                    ),
                  ]),
                  _menuSection(context, t.profileSectionSettings, [
                    _MenuItem(
                      icon: '✏️',
                      label: t.profileMenuEditProfile,
                      onTap: () => context.push('/edit-profile'),
                    ),
                    _MenuItem(
                      icon: '⚙️',
                      label: t.profileMenuAppSettings,
                      onTap: () => context.push('/settings'),
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _confirmLogout(context, ref, t),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFFCA5A5),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          t.profileLogoutButton,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      t.profileJoinDate(
                        DateFormat('yyyy. MM. dd').format(
                          DateTime.tryParse(user.createdAt) ?? DateTime.now(),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD1D5DB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuSection(
    BuildContext context,
    String title,
    List<_MenuItem> items,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 54),
                  items[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.profileLogoutButton),
        content: Text(t.profileLogoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.commonCancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(userProvider.notifier).logout();
              Navigator.pop(context);
            },
            child: Text(
              t.profileLogoutButton,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: const Color(0xFFF3F4F6));
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            SizedBox(width: 24, child: Text(icon, textAlign: TextAlign.center)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}

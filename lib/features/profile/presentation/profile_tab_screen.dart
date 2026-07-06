import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floating_contact_button.dart';
import '../../../shared/widgets/social_login_required_view.dart';
import '../../auth/application/user_notifier.dart';
import '../../library/application/library_notifier.dart';

/// Port of app/(tabs)/profile.tsx: 마이페이지.
class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    if (!userState.isLoggedIn) {
      return const Scaffold(
        body: SafeArea(
          child: SocialLoginRequiredView(
            emoji: '🔒',
            title: '로그인이 필요해요',
            description: '마이페이지를 이용하려면\n소셜 로그인이 필요합니다',
          ),
        ),
      );
    }

    final user = userState.user!;
    final lists = ref.watch(libraryProvider).lists;
    final publicListCount = lists.where((l) => l.isPublic).length;
    final isEarlyMember = user.badges.contains('초기멤버');

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
                          decoration: BoxDecoration(color: const Color(0xFFFFF0EB), shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2.5)),
                          child: const Center(child: Text('🐻', style: TextStyle(fontSize: 38))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                              Text(user.userId, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                              if (user.badges.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    for (final badge in user.badges)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: badge == '초기멤버' ? const Color(0xFFFFFBEB) : const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(10),
                                          border: badge == '초기멤버' ? Border.all(color: const Color(0xFFF59E0B)) : null,
                                        ),
                                        child: Text(badge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badge == '초기멤버' ? const Color(0xFFD97706) : const Color(0xFF6B7280))),
                                      ),
                                  ],
                                ),
                              ],
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
                        _StatItem(label: '보관함', value: '${lists.length}'),
                        const _StatDivider(),
                        _StatItem(label: '공개 리스트', value: '$publicListCount'),
                        const _StatDivider(),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 20)),
                              Text(
                                isEarlyMember ? '뱃지 확인하기' : '뱃지 없음',
                                style: TextStyle(fontSize: 12, color: isEarlyMember ? const Color(0xFFD97706) : AppColors.textSecondary, fontWeight: isEarlyMember ? FontWeight.w600 : FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEarlyMember)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFFCD34D))),
                      child: Row(
                        children: [
                          const Text('🏅', style: TextStyle(fontSize: 40)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('초기멤버 뱃지', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                                Text('당맷치 초기 1,000명 안에 가입한 특별한 멤버예요!\n가입 순번 #${user.joinOrder}', style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  _menuSection(context, '나의 기록', [
                    _MenuItem(icon: '🍽️', label: '나의 선택 기록', onTap: () => context.push('/my-selections')),
                  ]),
                  _menuSection(context, '설정', [
                    _MenuItem(icon: '✏️', label: '프로필 수정', onTap: () => context.push('/edit-profile')),
                    _MenuItem(icon: '⚙️', label: '앱 설정', onTap: () => context.push('/settings')),
                  ]),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _confirmLogout(context, ref),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text('로그아웃', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      '가입일: ${DateFormat('yyyy. MM. dd').format(DateTime.tryParse(user.createdAt) ?? DateTime.now())}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
                    ),
                  ),
                ],
              ),
            ),
            const FloatingContactButton(),
          ],
        ),
      ),
    );
  }

  Widget _menuSection(BuildContext context, String title, List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
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

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              ref.read(userProvider.notifier).logout();
              Navigator.pop(context);
            },
            child: const Text('로그아웃', style: TextStyle(color: AppColors.error)),
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
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 32, color: const Color(0xFFF3F4F6));
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap});
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
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF374151)))),
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}

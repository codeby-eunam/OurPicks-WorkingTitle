import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/user_notifier.dart';
import '../application/locale_notifier.dart';
import '../application/theme_notifier.dart';
import '../../../core/theme/app_palette.dart';

/// 개인 설정 화면 골격. RN에는 아직 없는 신규 화면 — 프로필/앱 설정 카테고리
/// 구조만 우선 잡고, 각 항목의 실제 동작(테마 전환, 캐시 삭제 등)은 추후 작업.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).user;
    final locale = ref.watch(localeProvider.select((s) => s.locale));
    final paletteId = ref.watch(themeProvider.select((s) => s.paletteId));
    final t = AppLocalizations.of(context)!;
    final languageValue = locale.languageCode == 'ko'
        ? t.languageKorean
        : t.languageEnglish;
    final themeValue = AppPalettes.byId(paletteId).labelKo;

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          if (user != null) ...[
            _SectionHeader(t.settingsProfileSection),
            _SettingsCard(
              children: [
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Center(
                      child: Text('🐻', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  title: Text(
                    user.nickname,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(user.userId),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFD1D5DB),
                  ),
                  onTap: () => context.push('/edit-profile'),
                ),
              ],
            ),
          ],
          _SectionHeader(t.settingsAppSection),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.language,
                label: t.settingsLanguageLabel,
                trailingText: languageValue,
                onTap: () => context.push('/language-picker?initial=false'),
              ),
              const Divider(height: 1, indent: 54),
              _SettingsTile(
                icon: Icons.palette_outlined,
                label: t.settingsThemeLabel,
                trailingText: themeValue,
                onTap: () => context.push('/theme-picker'),
              ),
              const Divider(height: 1, indent: 54),
              _SettingsTile(
                icon: Icons.delete_sweep_outlined,
                label: t.settingsClearCacheLabel,
                trailingText: t.settingsClearCacheValue,
                onTap: null,
              ),
            ],
          ),
          _SectionHeader(t.settingsInfoSection),
          _SettingsCard(
            children: [_AppVersionTile(label: t.settingsAppVersionLabel)],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailingText,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return ListTile(
      leading: Icon(
        icon,
        color: disabled ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: disabled ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
        ),
      ),
      trailing: trailingText != null
          ? Text(
              trailingText!,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          : const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
      onTap: onTap,
    );
  }
}

class _AppVersionTile extends StatelessWidget {
  const _AppVersionTile({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data != null
            ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : '';
        return ListTile(
          leading: const Icon(Icons.info_outline, color: Color(0xFF374151)),
          title: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
          trailing: Text(
            version,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../l10n/app_localizations.dart';
import '../application/theme_notifier.dart';

/// 설정 > 테마에서 A/B/C 팔레트를 미리보고 선택하는 화면 (design 브랜치 비교용).
class ThemePickerScreen extends ConsumerStatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  ConsumerState<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends ConsumerState<ThemePickerScreen> {
  late ThemePaletteId _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(themeProvider).paletteId;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.chooseThemeTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.chooseThemeSubtitle,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              for (final palette in AppPalettes.all) ...[
                _ThemeOption(
                  palette: palette,
                  selected: _selected == palette.id,
                  onTap: () => setState(() => _selected = palette.id),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(themeProvider.notifier)
                        .setPalette(_selected);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: Text(t.continueButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final ThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? palette.primary : AppColors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            _Swatch(color: palette.primary),
            const SizedBox(width: 6),
            _Swatch(color: palette.textPrimary),
            const SizedBox(width: 6),
            _Swatch(color: palette.background, bordered: true),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                palette.labelKo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: palette.primary, size: 22)
            else
              Icon(Icons.circle_outlined, color: AppColors.border, size: 22),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, this.bordered = false});

  final Color color;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: bordered ? Border.all(color: AppColors.border) : null,
      ),
    );
  }
}

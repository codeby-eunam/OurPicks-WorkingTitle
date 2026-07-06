import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';

class _ConfidenceOption {
  const _ConfidenceOption(this.level, this.emoji, this.label);
  final String level;
  final String emoji;
  final String label;
}

const _kOptions = [
  _ConfidenceOption('unsure', '😖', '아쉬워요'),
  _ConfidenceOption('okay', '😐', '그럭저럭'),
  _ConfidenceOption('confident', '😊', '만족해요'),
  _ConfidenceOption('very_confident', '🤩', '최고예요'),
];

/// Phase 1 '선택 확신도' 화면: 우승이 확정된 직후 이 선택에 얼마나 확신이
/// 드는지 가볍게 물어본다. 고르면 감사 메시지로 바뀌고 잠시 후 자동으로 닫힌다.
class ChoiceConfidenceSheet extends StatefulWidget {
  const ChoiceConfidenceSheet({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  State<ChoiceConfidenceSheet> createState() => _ChoiceConfidenceSheetState();
}

class _ChoiceConfidenceSheetState extends State<ChoiceConfidenceSheet> {
  String? _picked;

  Future<void> _pick(_ConfidenceOption option) async {
    setState(() => _picked = option.level);
    widget.onSelected(option.level);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.pillAll,
              ),
            ),
            if (_picked == null) ...[
              const Text(
                '이 선택, 확신이 들어요?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                '다음에 더 좋은 추천을 위해 알려주세요',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final option in _kOptions)
                    _OptionButton(option: option, onTap: () => _pick(option)),
                ],
              ),
            ] else ...[
              const Text('🙏', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              const Text(
                '소중한 의견 감사해요!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.option, required this.onTap});

  final _ConfidenceOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: AppColors.border,
            width: AppRadius.hairline,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              option.label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

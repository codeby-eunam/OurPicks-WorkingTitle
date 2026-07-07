import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../application/decision_session.dart';

/// 결정 세션이 후보군을 얼마나 좁혀왔는지 보여주는 퍼널 (예: 24 → 12 → 6 → 1).
/// 각 단계는 첫 단계 대비 비율만큼 너비가 줄어드는 막대로 표현한다.
class DecisionProgressFunnel extends StatelessWidget {
  const DecisionProgressFunnel({super.key, required this.stages});

  final List<FunnelStage> stages;

  @override
  Widget build(BuildContext context) {
    if (stages.length < 2) return const SizedBox.shrink();
    final maxCount = stages.first.count == 0 ? 1 : stages.first.count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘의 선택 과정',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < stages.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _FunnelRow(
            stage: stages[i],
            ratio: stages[i].count / maxCount,
            isLast: i == stages.length - 1,
          ),
        ],
      ],
    );
  }
}

class _FunnelRow extends StatelessWidget {
  const _FunnelRow({
    required this.stage,
    required this.ratio,
    required this.isLast,
  });

  final FunnelStage stage;
  final double ratio;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            stage.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio.clamp(0.08, 1.0),
            child: Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: isLast ? AppColors.primary : AppColors.secondary,
                borderRadius: AppRadius.smAll,
              ),
              child: Text(
                '${stage.count}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

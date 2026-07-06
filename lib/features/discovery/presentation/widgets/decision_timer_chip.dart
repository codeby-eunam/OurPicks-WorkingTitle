import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../application/decision_session.dart';

const _kNudgeAfter = Duration(minutes: 2);
const _kUrgentAfter = Duration(minutes: 5);

/// 결정 세션 경과 시간을 보여주는 칩. 2분이 지나면 주황, 5분이 지나면
/// 빨강으로 바뀌며 "그만 고민하고 결정하라"는 넛지를 준다.
class DecisionTimerChip extends StatefulWidget {
  const DecisionTimerChip({super.key, this.light = false});

  /// 어두운 배경(스와이프 틸) 위에 올릴 때 true.
  final bool light;

  @override
  State<DecisionTimerChip> createState() => _DecisionTimerChipState();
}

class _DecisionTimerChipState extends State<DecisionTimerChip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    DecisionSessionService.instance.beginIfAbsent();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = DecisionSessionService.instance.startedAt;
    final elapsed = startedAt == null ? Duration.zero : DateTime.now().difference(startedAt);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    final label = '$minutes:${seconds.toString().padLeft(2, '0')}';

    final Color fg;
    if (elapsed >= _kUrgentAfter) {
      fg = AppColors.error;
    } else if (elapsed >= _kNudgeAfter) {
      fg = AppColors.primary;
    } else {
      fg = widget.light ? Colors.white : AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: widget.light ? Colors.white.withValues(alpha: 0.18) : AppColors.surfaceMuted,
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

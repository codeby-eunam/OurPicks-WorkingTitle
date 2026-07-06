import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/application/user_notifier.dart';
import '../services/feedback_api.dart';

/// Port of components/floating-contact-button.tsx: a FAB that opens a
/// feedback bottom sheet, posting to /api/feedback/notify.
class FloatingContactButton extends ConsumerWidget {
  const FloatingContactButton({super.key, this.bottomOffset = 0});

  final double bottomOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      right: 20,
      bottom: 24 + bottomOffset,
      child: SizedBox(
        child: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(50),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () => _showFeedbackSheet(context, ref),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                '!',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _FeedbackSheet(ref: ref),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  bool get _isValid => _controller.text.trim().length >= 5;

  Future<void> _submit() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의 내용을 5자 이상 입력해주세요.')),
      );
      return;
    }

    setState(() => _sending = true);
    final user = widget.ref.read(userProvider).user;
    try {
      final ok = await FeedbackApi().sendFeedback(
        message: _controller.text.trim(),
        nickname: user?.nickname,
        uid: user?.userId,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('문의가 접수되었습니다. 빠르게 답변 드릴게요!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전송에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('문의하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            '불편한 점이나 개선 의견을 알려주세요.\n빠르게 검토하겠습니다!',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            maxLength: 500,
            maxLines: 5,
            minLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: '문의 내용을 입력해주세요...',
              filled: true,
              fillColor: Color(0xFFF3F4F6),
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _sending || !_isValid ? null : _submit,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('보내기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

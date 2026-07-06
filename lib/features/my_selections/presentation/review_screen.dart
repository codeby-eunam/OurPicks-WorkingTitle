import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/user_notifier.dart';
import '../data/user_log_api.dart';

/// Port of app/review.tsx.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.restaurantId, this.restaurantName});

  final String restaurantId;
  final String? restaurantName;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _commentController = TextEditingController();
  final _peopleController = TextEditingController();
  final _priceController = TextEditingController();
  bool _submitting = false;

  int? get _pricePerPerson {
    final people = int.tryParse(_peopleController.text);
    final price = int.tryParse(_priceController.text);
    if (people != null && people > 0 && price != null) {
      return (price / people).round();
    }
    return null;
  }

  Future<void> _submit() async {
    if (_commentController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('한 줄 후기를 5자 이상 작성해주세요')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = ref.read(userProvider).user;
      await UserLogApi().submitReview(
        userId: user?.kakaoId ?? '',
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName ?? '',
        comment: _commentController.text.trim(),
        peopleCount: int.tryParse(_peopleController.text),
        totalPrice: int.tryParse(_priceController.text),
        pricePerPerson: _pricePerPerson,
      );
      if (mounted) context.replace('/my-selections');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('등록 실패: 잠시 후 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricePerPerson = _pricePerPerson;

    return Scaffold(
      appBar: AppBar(title: const Text('리뷰 작성')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(widget.restaurantName ?? widget.restaurantId, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('한 줄 후기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 200,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '예) 매운 떡볶이가 최고였어요! (5자 이상)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('인원 수', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _peopleController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(hintText: '1', suffixText: '명'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('총 가격', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(hintText: '0', suffixText: '원'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (pricePerPerson != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFFFF7F4), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Text('1인 평균', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                    const SizedBox(width: 8),
                    Text('$pricePerPerson원', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('리뷰 등록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/user_notifier.dart';
import '../data/user_log_api.dart';

/// Port of app/my-selections.tsx.
class MySelectionsScreen extends ConsumerStatefulWidget {
  const MySelectionsScreen({super.key});

  @override
  ConsumerState<MySelectionsScreen> createState() => _MySelectionsScreenState();
}

class _MySelectionsScreenState extends ConsumerState<MySelectionsScreen> {
  List<UserLogEntry> _logs = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final user = ref.read(userProvider).user;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _error = false);
    try {
      final logs = await UserLogApi().fetchLogs(user.kakaoId);
      if (mounted) setState(() => _logs = logs);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime date) => DateFormat('yyyy.MM.dd').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('나의 선택 기록')),
      body: Stack(
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_error)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('불러오는 중 오류가 발생했어요.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _fetch, child: const Text('다시 시도')),
                ],
              ),
            )
          else if (_logs.isEmpty)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🍽️', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text('아직 선택한 맛집이 없어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('당맷치로 맛집을 골라보세요!', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${_logs.length}개의 기록', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _logs.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 18, endIndent: 18),
                        _buildRow(_logs[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRow(UserLogEntry item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatDate(item.selectedAtDate), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(item.restaurantName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
        ],
      ),
    );
  }
}

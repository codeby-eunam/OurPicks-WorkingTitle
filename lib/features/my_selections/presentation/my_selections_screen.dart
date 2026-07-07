import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.mySelectionsTitle)),
      body: Stack(
        children: [
          if (_loading)
            Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_error)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.mySelectionsErrorMessage,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _fetch,
                    child: Text(t.mySelectionsRetryButton),
                  ),
                ],
              ),
            )
          else if (_logs.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🍽️', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text(
                    t.mySelectionsEmptyTitle,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    t.mySelectionsEmptyMessage,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            Builder(
              builder: (context) {
                final today = _logs
                    .where((l) => _isToday(l.selectedAtDate))
                    .toList();
                final earlier = _logs
                    .where((l) => !_isToday(l.selectedAtDate))
                    .toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (today.isNotEmpty) ...[
                      _buildSectionHeader(t.mySelectionsTodaySection, t, today.length),
                      const SizedBox(height: 10),
                      _buildLogCard(today),
                      const SizedBox(height: 20),
                    ],
                    if (earlier.isNotEmpty) ...[
                      _buildSectionHeader(t.mySelectionsEarlierSection, t, earlier.length),
                      const SizedBox(height: 10),
                      _buildLogCard(earlier),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppLocalizations t, int count) {
    return Text(
      t.mySelectionsSectionCount(title, count),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildLogCard(List<UserLogEntry> logs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < logs.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 18, endIndent: 18),
            _buildRow(logs[i]),
          ],
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
          Text(
            _formatDate(item.selectedAtDate),
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            item.restaurantName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

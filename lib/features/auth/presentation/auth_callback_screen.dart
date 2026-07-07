import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../application/user_notifier.dart';

/// Port of app/auth/callback.tsx. On mobile, flutter_web_auth_2 already
/// captures the OAuth redirect directly inside loginWith(), so this route is
/// mainly a safety net for cold-start deep links or the web build (kept for
/// route parity with the RN app).
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key, required this.queryParams});

  final Map<String, String> queryParams;

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _process());
  }

  Future<void> _process() async {
    final params = widget.queryParams;
    final hasSocialId =
        params['kakaoId'] != null ||
        params['naverId'] != null ||
        params['googleId'] != null;
    if (!hasSocialId && params['error'] == null) return;

    try {
      if (params['error'] != null) {
        if (mounted) context.go('/landing');
        return;
      }

      final result = ref.read(userProvider.notifier).processOAuthParams(params);
      if (!mounted) return;
      if (result.needsSetup) {
        context.replace(
          '/setup-profile',
          extra: {'kakaoId': result.kakaoId, 'provider': result.provider.name},
        );
      } else {
        context.go('/');
      }
    } catch (_) {
      if (mounted) context.go('/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

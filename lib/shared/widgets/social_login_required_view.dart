import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/user_notifier.dart';
import '../models/app_user.dart';

/// Shared "로그인이 필요해요" panel used by the 보관함/마이 탭 when logged out
/// (app/(tabs)/library.tsx and app/(tabs)/profile.tsx render an identical
/// login-required block with the same 3 social buttons).
class SocialLoginRequiredView extends ConsumerStatefulWidget {
  const SocialLoginRequiredView({super.key, required this.emoji, required this.title, required this.description});

  final String emoji;
  final String title;
  final String description;

  @override
  ConsumerState<SocialLoginRequiredView> createState() => _SocialLoginRequiredViewState();
}

class _SocialLoginRequiredViewState extends ConsumerState<SocialLoginRequiredView> {
  AuthProvider? _loadingProvider;

  Future<void> _handleLogin(AuthProvider provider) async {
    setState(() => _loadingProvider = provider);
    try {
      final result = await ref.read(userProvider.notifier).loginWith(provider);
      if (result == null) {
        setState(() => _loadingProvider = null);
        return;
      }
      if (!mounted) return;
      if (result.needsSetup) {
        context.push(
          '/setup-profile',
          extra: {
            'kakaoId': result.kakaoId,
            'profileImage': result.profileImage ?? '',
            'provider': result.provider.name,
          },
        );
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인에 실패했습니다: ${err.toString().replaceFirst('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _loadingProvider = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastUsed = ref.watch(userProvider).lastUsedProvider;
    final isLoading = _loadingProvider != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text(widget.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280), height: 1.45)),
            const SizedBox(height: 20),
            _loginButton(
              provider: AuthProvider.kakao,
              background: const Color(0xFFFEE500),
              foreground: const Color(0xFF3C1E1E),
              icon: '💬',
              label: '카카오로 로그인',
              recent: lastUsed == AuthProvider.kakao,
              isLoading: isLoading,
            ),
            const SizedBox(height: 10),
            _loginButton(
              provider: AuthProvider.naver,
              background: const Color(0xFF03C75A),
              foreground: Colors.white,
              icon: 'N',
              label: '네이버로 로그인',
              recent: lastUsed == AuthProvider.naver,
              isLoading: isLoading,
            ),
            const SizedBox(height: 10),
            _loginButton(
              provider: AuthProvider.google,
              background: Colors.white,
              foreground: const Color(0xFF374151),
              iconColor: const Color(0xFF4285F4),
              border: const Color(0xFFE5E7EB),
              icon: 'G',
              label: '구글로 로그인',
              recent: lastUsed == AuthProvider.google,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginButton({
    required AuthProvider provider,
    required Color background,
    required Color foreground,
    required String icon,
    required String label,
    required bool recent,
    required bool isLoading,
    Color? iconColor,
    Color? border,
  }) {
    final thisLoading = _loadingProvider == provider;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _handleLogin(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: border != null ? BorderSide(color: border, width: 1.5) : BorderSide.none,
          ),
        ),
        child: thisLoading
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: foreground))
            : Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icon, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: iconColor ?? foreground)),
                      const SizedBox(width: 8),
                      Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: foreground)),
                    ],
                  ),
                  if (recent)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                        child: Text('최근 사용', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: foreground)),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

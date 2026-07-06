import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/widgets/floating_contact_button.dart';
import '../application/user_notifier.dart';
import '../application/user_state.dart';

/// Port of app/landing.tsx: social login (Kakao/Naver/Google) or guest entry.
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  AuthProvider? _loadingProvider;

  Future<void> _handleSocialLogin(AuthProvider provider) async {
    setState(() => _loadingProvider = provider);
    try {
      final result = await ref.read(userProvider.notifier).loginWith(provider);
      if (result == null) {
        setState(() => _loadingProvider = null);
        return;
      }
      if (!mounted) return;
      if (result.needsSetup) {
        context.replace(
          '/setup-profile',
          extra: {
            'kakaoId': result.kakaoId,
            'profileImage': result.profileImage ?? '',
            'provider': result.provider.name,
          },
        );
      } else {
        context.go('/');
      }
    } catch (err) {
      if (!mounted) return;
      setState(() => _loadingProvider = null);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로그인 오류'),
          content: Text(err.toString().replaceFirst('Exception: ', '')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
          ],
        ),
      );
    }
  }

  void _handleSkip() {
    ref.read(userProvider.notifier).setHasSeenLanding();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isLoading = _loadingProvider != null;
    final height = MediaQuery.of(context).size.height;
    final compact = height < 750;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: SafeAreaView(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 24, vertical: compact ? 16 : 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBranding(compact),
                  _buildFeatures(compact),
                  _buildButtons(userState, compact, isLoading),
                ],
              ),
            ),
            const FloatingContactButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBranding(bool compact) {
    return Column(
      children: [
        Container(
          width: compact ? 64 : 88,
          height: compact ? 64 : 88,
          margin: EdgeInsets.only(bottom: compact ? 10 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF006D77),
            borderRadius: BorderRadius.circular(compact ? 18 : 26),
          ),
          child: Center(
            child: Text('🐻', style: TextStyle(fontSize: compact ? 32 : 44)),
          ),
        ),
        Text(
          '당맷치',
          style: TextStyle(
            fontSize: compact ? 24 : 34,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: compact ? 2 : 6),
        Text(
          '오늘 뭐 먹을지, 고민 끝!',
          style: TextStyle(fontSize: compact ? 13 : 16, fontWeight: FontWeight.w700, color: const Color(0xFFFF6B35)),
        ),
        SizedBox(height: compact ? 0 : 4),
        Text(
          '위치 기반 맛집 추천 & 나만의 보관함',
          style: TextStyle(fontSize: compact ? 11 : 13, color: const Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _buildFeatures(bool compact) {
    const items = [
      ('📍', '내 주변 맛집을 탐색해요'),
      ('🎲', '스와이프 & 토너먼트로 결정해요'),
      ('📂', '보관함에 맛집을 저장해요'),
    ];
    return Column(
      children: [
        for (final (emoji, text) in items) ...[
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: compact ? 5 : 8),
            padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: compact ? 8 : 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(compact ? 10 : 14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: compact ? 18 : 22)),
                SizedBox(width: compact ? 10 : 12),
                Text(text, style: TextStyle(fontSize: compact ? 12 : 14, fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildButtons(UserState userState, bool compact, bool isLoading) {
    return Column(
      children: [
        _SocialButton(
          backgroundColor: const Color(0xFFFEE500),
          textColor: const Color(0xFF3C1E1E),
          icon: '💬',
          label: '카카오로 로그인',
          isRecent: userState.lastUsedProvider == AuthProvider.kakao,
          isLoading: _loadingProvider == AuthProvider.kakao,
          disabled: isLoading,
          onTap: () => _handleSocialLogin(AuthProvider.kakao),
          compact: compact,
        ),
        SizedBox(height: compact ? 6 : 8),
        _SocialButton(
          backgroundColor: const Color(0xFF03C75A),
          textColor: Colors.white,
          icon: 'N',
          label: '네이버로 로그인',
          isRecent: userState.lastUsedProvider == AuthProvider.naver,
          isLoading: _loadingProvider == AuthProvider.naver,
          disabled: isLoading,
          onTap: () => _handleSocialLogin(AuthProvider.naver),
          compact: compact,
        ),
        SizedBox(height: compact ? 6 : 8),
        _SocialButton(
          backgroundColor: Colors.white,
          textColor: const Color(0xFF374151),
          icon: 'G',
          iconColor: const Color(0xFF4285F4),
          label: '구글로 로그인',
          border: const Color(0xFFE5E7EB),
          isRecent: userState.lastUsedProvider == AuthProvider.google,
          isLoading: _loadingProvider == AuthProvider.google,
          disabled: isLoading,
          onTap: () => _handleSocialLogin(AuthProvider.google),
          compact: compact,
        ),
        SizedBox(height: compact ? 6 : 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading ? null : _handleSkip,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: compact ? 10 : 13),
              side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              '로그인 없이 시작하기',
              style: TextStyle(fontSize: compact ? 14 : 14, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 12),
          const Text(
            '로그인 시 보관함과 마이페이지를 이용할 수 있어요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.label,
    required this.isRecent,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
    required this.compact,
    this.iconColor,
    this.border,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color? iconColor;
  final Color? border;
  final String icon;
  final String label;
  final bool isRecent;
  final bool isLoading;
  final bool disabled;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: EdgeInsets.symmetric(vertical: compact ? 12 : 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: border != null ? BorderSide(color: border!, width: 1.5) : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icon, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: iconColor ?? textColor)),
                      const SizedBox(width: 8),
                      Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                    ],
                  ),
                  if (isRecent)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('최근 사용', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// SafeArea shorthand matching RN's SafeAreaView with edges top/bottom.
class SafeAreaView extends StatelessWidget {
  const SafeAreaView({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(child: child);
}

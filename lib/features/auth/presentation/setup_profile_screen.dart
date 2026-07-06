import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/widgets/floating_contact_button.dart';
import '../application/user_notifier.dart';

/// @로 시작, 영문 첫 글자, 이후 영문/숫자/./_ 조합, 2~20자 (@ 포함 총 3~21자).
/// app/setup-profile.tsx의 USER_ID_REGEX 그대로.
final _userIdRegex = RegExp(r'^@[a-zA-Z][a-zA-Z0-9._]{1,19}$');

/// Port of app/setup-profile.tsx: new-user id + nickname setup.
class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({
    super.key,
    required this.kakaoId,
    required this.provider,
  });

  final String kakaoId;
  final String provider;

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _userIdController = TextEditingController(text: '@');
  final _nicknameController = TextEditingController();
  String _userIdError = '';
  bool _checking = false;
  bool _submitting = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  String _validateFormat(String value) {
    if (value.isEmpty || value == '@') return '아이디를 입력해주세요';
    if (value.length < 3) return '@로 시작하는 2자 이상 입력해주세요';
    if (!_userIdRegex.hasMatch(value)) {
      return '영문자로 시작하고 영문/숫자/. /_ 만 사용 가능해요 (2~20자)';
    }
    return '';
  }

  void _onUserIdChanged(String value) {
    if (!value.startsWith('@')) return; // @ 제거 방지
    final lower = value.toLowerCase();
    if (lower != value) {
      final selection = _userIdController.selection;
      _userIdController.value = TextEditingValue(text: lower, selection: selection);
    }
    setState(() => _userIdError = '');
  }

  bool get _isFormReady =>
      _userIdRegex.hasMatch(_userIdController.text) && _nicknameController.text.trim().isNotEmpty;

  bool get _isLoading => _checking || _submitting;

  Future<void> _handleSubmit() async {
    final userId = _userIdController.text;
    final formatError = _validateFormat(userId);
    if (formatError.isNotEmpty) {
      setState(() => _userIdError = formatError);
      return;
    }
    if (_nicknameController.text.trim().isEmpty) {
      _showAlert('알림', '닉네임을 입력해주세요.');
      return;
    }

    setState(() => _checking = true);
    try {
      final available = await ref.read(userProvider.notifier).checkUserIdAvailable(userId);
      if (!available) {
        setState(() => _userIdError = '이미 사용 중인 아이디예요. 다른 아이디를 입력해주세요.');
        return;
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }

    setState(() => _submitting = true);
    try {
      await ref.read(userProvider.notifier).setupProfile(
            userId: userId,
            nickname: _nicknameController.text.trim(),
            kakaoId: widget.kakaoId,
            provider: AuthProvider.fromName(widget.provider.isEmpty ? 'kakao' : widget.provider),
          );
      if (mounted) context.go('/');
    } catch (err) {
      _showAlert('오류', '프로필 설정에 실패했습니다.\n${err.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('프로필 설정',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '당맷치에서 사용할\n아이디와 닉네임을 만들어요',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  const Text('아이디는 한 번 설정하면 변경이 어려워요',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 36),

                  _label('아이디'),
                  TextField(
                    controller: _userIdController,
                    onChanged: _onUserIdChanged,
                    maxLength: 21,
                    decoration: _inputDecoration('@your_id', error: _userIdError.isNotEmpty),
                  ),
                  if (_userIdError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('⚠️ $_userIdError', style: const TextStyle(fontSize: 12, color: AppColors.error)),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('@로 시작 · 영문/숫자/. /_ 사용 가능 · 2~20자',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  const SizedBox(height: 28),

                  _label('닉네임'),
                  TextField(
                    controller: _nicknameController,
                    maxLength: 20,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _handleSubmit(),
                    decoration: _inputDecoration('예: 맛집헌터, 고민쟁이'),
                  ),
                  const SizedBox(height: 28),

                  if (_userIdController.text.length > 1 || _nicknameController.text.isNotEmpty)
                    _buildPreviewCard(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (!_isFormReady || _isLoading) ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('완료', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const FloatingContactButton(),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(
          TextSpan(text: text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)), children: const [
            TextSpan(text: ' *', style: TextStyle(color: AppColors.primary)),
          ]),
        ),
      );

  InputDecoration _inputDecoration(String hint, {bool error = false}) {
    final borderColor = error ? AppColors.error : const Color(0xFFE5E7EB);
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFC4C9D1)),
      filled: true,
      fillColor: error ? const Color(0xFFFFF5F5) : const Color(0xFFFAFAFA),
      counterText: '',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor, width: 1.5)),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('미리보기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Center(child: Text('🐻', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_nicknameController.text.trim().isEmpty ? '닉네임' : _nicknameController.text.trim(),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text(_userIdController.text.length > 1 ? _userIdController.text : '@아이디',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

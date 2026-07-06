import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/floating_contact_button.dart';
import '../application/user_notifier.dart';

/// Port of app/edit-profile.tsx: nickname-only edit (userId is immutable).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nicknameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: ref.read(userProvider).user?.nickname ?? '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(String currentNickname) async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty || nickname == currentNickname) return;

    setState(() => _saving = true);
    try {
      await ref.read(userProvider.notifier).updateNickname(nickname);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('저장 완료'),
          content: const Text('닉네임이 변경되었어요.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('오류'),
          content: Text(err.toString().replaceFirst('Exception: ', '')),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).user;
    if (user == null) return const SizedBox.shrink();

    final nickname = _nicknameController.text.trim();
    final isChanged = nickname != user.nickname;
    final isReady = nickname.isNotEmpty && isChanged;

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 수정')),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                      ),
                      child: const Center(child: Text('🐻', style: TextStyle(fontSize: 48))),
                    ),
                  ),
                  const SizedBox(height: 36),

                  const Text('아이디', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceMuted, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(user.userId, style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(6)),
                          child: const Text('변경 불가', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('아이디는 고유 식별자로 변경이 어려워요', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 28),

                  const Text.rich(
                    TextSpan(text: '닉네임', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)), children: [
                      TextSpan(text: ' *', style: TextStyle(color: AppColors.primary)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nicknameController,
                    maxLength: 20,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _handleSave(user.nickname),
                    decoration: InputDecoration(
                      hintText: '닉네임을 입력해주세요',
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceMuted),
                    ),
                    child: Row(
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
                            Text(nickname.isEmpty ? user.nickname : nickname,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            Text(user.userId, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (!isReady || _saving) ? null : () => _handleSave(user.nickname),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('저장하기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
}

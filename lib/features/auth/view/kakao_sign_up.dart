// lib/features/auth/view/kakao_sign_up.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/widgets/back_button.dart';
import 'package:moods/features/auth/controller/auth_controller.dart';

class AdditionalInfoScreen extends ConsumerStatefulWidget {
  const AdditionalInfoScreen({super.key});
  @override
  ConsumerState<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends ConsumerState<AdditionalInfoScreen> {
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  String selectedGender = '';

  @override
  void initState() {
    super.initState();
    birthController.addListener(_formatBirthday);
  }

  @override
  void dispose() {
    birthController.removeListener(_formatBirthday);
    birthController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  void _formatBirthday() {
    final digits = birthController.text.replaceAll('.', '');
    final b = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      b.write(digits[i]);
      if ((i == 3 || i == 5) && i != digits.length - 1) b.write('.');
    }
    final f = b.toString();
    if (f != birthController.text) {
      birthController.value = TextEditingValue(
        text: f,
        selection: TextSelection.collapsed(offset: f.length),
      );
    }
    setState(() {});
  }

  String? _validate() {
    if (nicknameController.text.trim().isEmpty) return '닉네임 입력해라.';
    if (birthController.text.length != 10) return '생년월일 형식은 YYYY.MM.DD';
    if (selectedGender.isEmpty) return '성별 선택해라.';
    final y = int.tryParse(birthController.text.substring(0, 4));
    final m = int.tryParse(birthController.text.substring(5, 7));
    final d = int.tryParse(birthController.text.substring(8, 10));
    if (y == null || m == null || d == null) return '생년월일 형식 확인해라.';
    try { DateTime(y, m, d); } catch (_) { return '존재하지 않는 날짜다.'; }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    final nickname = nicknameController.text.trim();
    final birthday = birthController.text.replaceAll('.', '-'); // YYYY-MM-DD
    final genderLetter = (selectedGender == '남성') ? 'm' : 'f';

    final ok = await ref.read(authControllerProvider.notifier).completeOnboarding(
          nickname: nickname,
          genderLetter: genderLetter,
          birthday: birthday,
        );

    if (!mounted) return;

    if (ok) {
      context.go('/complete'); // or '/home'
    } else {
      final msg = ref.read(authErrorProvider) ?? '알 수 없는 오류';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    final isNextEnabled = nicknameController.text.isNotEmpty &&
        birthController.text.length == 10 &&
        selectedGender.isNotEmpty &&
        !loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const GlobalBackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('추가 정보를\n입력해주세요',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),

            const Text('닉네임', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(
                fillColor: Colors.white, filled: true, hintText: '닉네임',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(width: 1, color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(width: 1, color: AppColors.border),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 24),
            const Text('생년월일', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            TextField(
              controller: birthController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                counterText: '',
                fillColor: Colors.white, filled: true, hintText: 'YYYY.MM.DD',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(width: 1, color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(width: 1, color: AppColors.border),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text('성별', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedGender = '남성'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedGender == '남성' ? AppColors.main : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12), bottomLeft: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text('남성',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                  Container(width: 1, height: double.infinity, color: Color(0xFFE9E8F1)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => selectedGender = '여성'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedGender == '여성' ? AppColors.main : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12), bottomRight: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text('여성',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isNextEnabled ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isNextEnabled ? AppColors.main : AppColors.unchecked,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.unchecked,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

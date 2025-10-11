import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/widgets/back_button.dart';
import 'package:moods/features/auth/controller/auth_controller.dart';
import 'package:moods/providers.dart';

/// 회원정보 수정 화면
/// - 닉네임/생년월일/성별만 수정
/// - 제출 시 기존 온보딩 로직(completeOnboarding -> PATCH /user) 재사용
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({
    super.key,
    this.initialNickname,
    this.initialBirthday, // 'YYYY-MM-DD' 또는 'YYYY.MM.DD' 둘 다 허용
    this.initialGender, // 'm'|'f' 또는 '남성'|'여성' 허용
    this.onSuccessRoute, // 성공 후 이동 경로(없으면 context.pop)
  });

  final String? initialNickname;
  final String? initialBirthday;
  final String? initialGender;
  final String? onSuccessRoute;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nicknameController = TextEditingController();
  final _birthController = TextEditingController();
  String _selectedGender = ''; // '남성' | '여성'

  @override
  void initState() {
    super.initState();

    // 초기값 세팅
    _nicknameController.text = widget.initialNickname ?? '';

    final birth0 = widget.initialBirthday ?? '';
    _birthController.text = _toDotDate(birth0); // 내부 입력은 항상 YYYY.MM.DD 로 유지

    _selectedGender = _normalizeGenderToKor(widget.initialGender ?? '');

    _birthController.addListener(_formatBirthday);
  }

  @override
  void dispose() {
    _birthController.removeListener(_formatBirthday);
    _birthController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  // 입력: 'YYYY-MM-DD' 또는 'YYYY.MM.DD' 또는 ''
  // 출력: 'YYYY.MM.DD' 또는 ''
  String _toDotDate(String raw) {
    if (raw.isEmpty) return '';
    final onlyDigits = raw.replaceAll('.', '-');
    if (onlyDigits.length == 10 &&
        onlyDigits[4] == '-' &&
        onlyDigits[7] == '-') {
      // YYYY-MM-DD -> YYYY.MM.DD
      return '${onlyDigits.substring(0, 4)}.'
          '${onlyDigits.substring(5, 7)}.'
          '${onlyDigits.substring(8, 10)}';
    }
    // 이미 '.' 형식이면 그대로 반환(간단 방어)
    if (raw.length == 10 && raw[4] == '.' && raw[7] == '.') return raw;
    return raw;
  }

  // 입력: 'm'|'f'|'남성'|'여성'|기타
  // 출력: '남성'|'여성'|''
  String _normalizeGenderToKor(String g) {
    final s = g.trim().toLowerCase();
    if (s == 'm' || s == '남성') return '남성';
    if (s == 'f' || s == '여성') return '여성';
    return '';
  }

  // TextField에 타이핑 되는 즉시 YYYY.MM.DD 형식 유지
  void _formatBirthday() {
    final digits = _birthController.text.replaceAll('.', '');
    final b = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      b.write(digits[i]);
      if ((i == 3 || i == 5) && i != digits.length - 1) b.write('.');
    }
    final f = b.toString();
    if (f != _birthController.text) {
      _birthController.value = TextEditingValue(
        text: f,
        selection: TextSelection.collapsed(offset: f.length),
      );
    }
    setState(() {}); // 하단 버튼 활성화 갱신
  }

  String? _validate() {
    if (_nicknameController.text.trim().isEmpty) return '닉네임을 입력하세요.';
    if (_birthController.text.length != 10) return '생년월일 형식은 YYYY.MM.DD 입니다.';
    if (_selectedGender.isEmpty) return '성별을 선택하세요.';
    final y = int.tryParse(_birthController.text.substring(0, 4));
    final m = int.tryParse(_birthController.text.substring(5, 7));
    final d = int.tryParse(_birthController.text.substring(8, 10));
    if (y == null || m == null || d == null) return '생년월일 형식을 확인하세요.';
    try {
      DateTime(y, m, d);
    } catch (_) {
      return '존재하지 않는 날짜입니다.';
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    final nickname = _nicknameController.text.trim();
    final birthday = _birthController.text.replaceAll('.', '-'); // YYYY-MM-DD
    final genderLetter = (_selectedGender == '남성') ? 'm' : 'f';

    final ok = await ref
        .read(authControllerProvider.notifier)
        .completeOnboarding(
          nickname: nickname,
          genderLetter: genderLetter,
          birthday: birthday,
        );

    if (!mounted) return;

    if (ok) {
      // 성공 후 이동: 주어진 라우트가 있으면 go, 없으면 pop
      if (widget.onSuccessRoute != null && widget.onSuccessRoute!.isNotEmpty) {
        context.go(widget.onSuccessRoute!);
      } else {
        context.pop(true); // 호출측에서 true로 처리 가능
      }
    } else {
      final msg = ref.read(authErrorProvider) ?? '수정 중 오류가 발생했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    final isConfirmEnabled =
        _nicknameController.text.isNotEmpty &&
        _birthController.text.length == 10 &&
        _selectedGender.isNotEmpty &&
        !loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const GlobalBackButton(),
        centerTitle: true,
        title: const Text(
          '회원정보 수정하기',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              '닉네임',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                hintText: '닉네임',
                fillColor: Colors.white,
                filled: true,
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
            const Text(
              '생년월일',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _birthController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'YYYY.MM.DD',
                fillColor: Colors.white,
                filled: true,
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
            const Text(
              '성별',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
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
                      onTap: () => setState(() => _selectedGender = '남성'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedGender == '남성'
                              ? AppColors.main
                              : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '남성',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: double.infinity,
                    color: Color(0xFFE9E8F1),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = '여성'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selectedGender == '여성'
                              ? AppColors.main
                              : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '여성',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                onPressed: isConfirmEnabled ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConfirmEnabled
                      ? AppColors.main
                      : AppColors.unchecked,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.unchecked,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

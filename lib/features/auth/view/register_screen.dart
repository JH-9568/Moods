import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/features/auth/controller/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController emailIdController = TextEditingController();
  final TextEditingController emailCustomDomainController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  String selectedGender = '';
  String selectedDomain = '직접입력';

  bool isVerificationSent = false;
  bool isVerified = false;
  String? verificationId;

  Timer? _verificationTimer;

  final GlobalKey _domainKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    birthController.addListener(_formatBirthday);
    emailIdController.addListener(_checkNextButtonState);
    emailCustomDomainController.addListener(_checkNextButtonState);
    passwordController.addListener(_checkNextButtonState);
    passwordConfirmController.addListener(_checkNextButtonState);
    nicknameController.addListener(_checkNextButtonState);
    birthController.addListener(_checkNextButtonState);
  }

  @override
  void dispose() {
    emailIdController.dispose();
    emailCustomDomainController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    nicknameController.dispose();
    birthController.removeListener(_formatBirthday);
    birthController.dispose();
    _verificationTimer?.cancel();
    super.dispose();
  }

  void _formatBirthday() {
    String digits = birthController.text.replaceAll('.', '');
    String formatted = '';
    for (int i = 0; i < digits.length && i < 8; i++) {
      formatted += digits[i];
      if ((i == 3 || i == 5) && i != digits.length - 1) {
        formatted += '.';
      }
    }
    if (formatted != birthController.text) {
      birthController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _checkNextButtonState() {
    setState(() {});
  }

  String _getFullEmail() {
    final id = emailIdController.text.trim();
    final domain = selectedDomain == '직접입력'
        ? emailCustomDomainController.text.trim()
        : selectedDomain.trim();
    return '$id@$domain';
  }

  void _startVerificationTimer() {
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (verificationId == null) return;
      final controller = ref.read(authControllerProvider.notifier);
      try {
        final verified = await controller.checkEmailVerified(verificationId!);
        if (verified) {
          setState(() {
            isVerified = true;
          });
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이메일 인증이 완료되었습니다.')),
            );
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _handleEmailVerification() async {
    final email = _getFullEmail();
    final isEmailValid = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

    if (!isEmailValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('올바른 이메일 형식을 입력해주세요.')),
        );
      }
      return;
    }

    final controller = ref.read(authControllerProvider.notifier);
    try {
      if (!isVerificationSent) {
        final uuid = await controller.requestInitialVerification(
          email: email,
          password: passwordController.text,
          nickname: nicknameController.text,
          birth: birthController.text,
          gender: selectedGender,
        );

        if (uuid == null) {
          throw Exception('UUID 반환 실패 (서버 응답 확인 필요)');
        }

        verificationId = uuid;

        setState(() {
          isVerificationSent = true;
          isVerified = false;
        });

        _startVerificationTimer();
      } else {
        await controller.sendVerificationCode(email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인증번호를 재전송했습니다.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('인증 요청 실패: $e')),
        );
      }
    }
  }

  Future<void> _onSubmit() async {
    final email = _getFullEmail();
    final controller = ref.read(authControllerProvider.notifier);

    await controller.confirmSignUp(
      email: email,
      password: passwordController.text,
      nickname: nicknameController.text,
      birth: birthController.text,
      gender: selectedGender,
    );
    if (mounted) context.go('/terms');
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool obscure = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildLabeledField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label), const SizedBox(height: 8), child],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color.fromRGBO(175, 175, 175, 1)),
      filled: true,
      fillColor: AppColors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.border, width: 2),
      ),
    );
  }

  Widget _buildEmailDomainSelector() {
    final fullDomainList = ['직접입력', 'naver.com', 'gmail.com', 'daum.net', 'nate.com'];
    final filteredDomainList = fullDomainList.where((domain) => domain != selectedDomain).toList();

    return GestureDetector(
      key: _domainKey,
      onTap: () async {
        final RenderBox renderBox = _domainKey.currentContext?.findRenderObject() as RenderBox;
        final offset = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        final selected = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            offset.dx,
            offset.dy + size.height,
            offset.dx + size.width,
            offset.dy + size.height,
          ),
          constraints: BoxConstraints(minWidth: size.width, maxWidth: size.width),
          color: AppColors.gray1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.border),
          ),
          elevation: 0,
          items: filteredDomainList.map((domain) {
            return PopupMenuItem<String>(
              value: domain,
              padding: EdgeInsets.zero,
              child: Container(
                height: 40,
                width: double.infinity,
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  domain,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.grayText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        );

        if (selected != null) {
          setState(() {
            selectedDomain = selected;
            if (selected == '직접입력') {
              emailCustomDomainController.clear();
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: selectedDomain == '직접입력'
                  ? TextField(
                      controller: emailCustomDomainController,
                      decoration: const InputDecoration.collapsed(
                        hintText: '직접입력',
                        hintStyle: TextStyle(color: Color.fromRGBO(175, 175, 175, 1)),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (_) => setState(() {}),
                    )
                  : Text(
                      selectedDomain,
                      style: const TextStyle(fontSize: 14),
                    ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.grayText),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _genderButton('남성'),
          Container(width: 1, height: double.infinity, color: AppColors.border),
          _genderButton('여성'),
        ],
      ),
    );
  }

  Widget _genderButton(String gender) {
    final isSelected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedGender = gender),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.main : AppColors.white,
            borderRadius: gender == '남성'
                ? const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12))
                : const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
          ),
          alignment: Alignment.center,
          child: Text(gender, style: const TextStyle(color: AppColors.black, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNextEnabled =
        emailIdController.text.isNotEmpty &&
        (selectedDomain != '직접입력' || emailCustomDomainController.text.isNotEmpty) &&
        passwordController.text.isNotEmpty &&
        passwordConfirmController.text == passwordController.text &&
        nicknameController.text.isNotEmpty &&
        birthController.text.length == 10 &&
        selectedGender.isNotEmpty &&
        isVerified;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
  backgroundColor: AppColors.background,
  elevation: 0,
  centerTitle: true,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black),
    onPressed: () {
      context.go('/start'); 
    },
  ),
  title: const Text('회원가입', style: TextStyle(color: AppColors.black)),
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '회원 정보를\n입력해주세요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            const Text('이메일'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField(emailIdController, '이메일')),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('@')),
                Expanded(flex: 2, child: _buildEmailDomainSelector()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: !isVerified && emailIdController.text.isNotEmpty &&
                            (selectedDomain != '직접입력' || emailCustomDomainController.text.isNotEmpty)
                        ? _handleEmailVerification
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isVerified && (emailIdController.text.isNotEmpty &&
                              (selectedDomain != '직접입력' || emailCustomDomainController.text.isNotEmpty))
                          ? AppColors.main
                          : AppColors.unchecked,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isVerificationSent ? '인증번호 재전송' : '인증번호 요청'),
                  ),
                ),
              ],
            ),
            if (isVerificationSent && !isVerified)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  '이메일에서 인증 버튼을 클릭해 주세요',
                  style: TextStyle(fontSize: 12, color: AppColors.main),
                ),
              ),
            const SizedBox(height: 16),
            _buildLabeledField('비밀번호', _buildTextField(passwordController, '8~20자 영문, 숫자의 조합으로 입력해 주세요', obscure: true)),
            const SizedBox(height: 16),
            _buildLabeledField('비밀번호 확인', _buildTextField(passwordConfirmController, '비밀번호 확인', obscure: true)),
            if (passwordConfirmController.text.isNotEmpty && passwordConfirmController.text != passwordController.text)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  '비밀번호가 일치하지 않습니다.',
                  style: TextStyle(fontSize: 12, color: AppColors.main),
                ),
              ),
            const SizedBox(height: 16),
            _buildLabeledField('닉네임', _buildTextField(nicknameController, '예시')),
            const SizedBox(height: 16),
            _buildLabeledField('생년월일', _buildTextField(birthController, 'YYYY.MM.DD', keyboardType: TextInputType.number)),
            const SizedBox(height: 16),
            const Text('성별'),
            const SizedBox(height: 8),
            _buildGenderSelector(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isNextEnabled ? _onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isNextEnabled ? AppColors.main : AppColors.unchecked,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text('다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
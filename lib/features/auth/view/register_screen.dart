import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailIdController = TextEditingController();
  final TextEditingController emailVerifyController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  String selectedGender = '';
  String selectedDomain = '직접입력';
  bool isCodeRequested = false;

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

  @override
  void initState() {
    super.initState();
    birthController.addListener(_formatBirthday);
  }

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    emailIdController.dispose();
    emailVerifyController.dispose();
    nicknameController.dispose();
    birthController.removeListener(_formatBirthday);
    birthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNextEnabled = idController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        emailIdController.text.isNotEmpty &&
        emailVerifyController.text.isNotEmpty &&
        nicknameController.text.isNotEmpty &&
        birthController.text.length == 10 &&
        selectedGender.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: const Text('회원가입', style: TextStyle(color: Colors.black)),
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
            _buildLabeledField('아이디', TextField(
                controller: idController,
                decoration: _inputDecoration('아이디를 입력하세요').copyWith(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: AppColors.border, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {})
            )
            ),
            const SizedBox(height: 16),
            _buildLabeledField(
                '비밀번호',
                TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('8~20자 영문, 숫자의 조합으로 입력해 주세요')
                        .copyWith(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.border, width: 2),
                      ),
                    ),
                    onChanged: (_) => setState(() {})
                )
            ),
            const SizedBox(height: 16),
            const Text('이메일'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                      controller: emailIdController,
                      decoration: _inputDecoration('이메일').copyWith(
                        filled: true,
                        fillColor: Colors.white,
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
                      ),
                      onChanged: (_) => setState(() {})),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('@'),
                ),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: selectedDomain,
                    onChanged: (v) => setState(() => selectedDomain = v!),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border, width: 2),
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    dropdownColor: Colors.white,
                    items: ['직접입력', 'naver.com', 'gmail.com', 'daum.net']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                      controller: emailVerifyController,
                      decoration: _inputDecoration('인증번호 입력').copyWith(
                        filled: true,
                        fillColor: Colors.white,
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
                      ),
                      onChanged: (_) => setState(() {})),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isCodeRequested = true;
                        });
                        // TODO: 실제 인증번호 요청 로직 추가
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFCFCCF9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isCodeRequested ? '인증번호 재요청' : '인증번호 요청',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabeledField(
              '닉네임',
              TextField(
                controller: nicknameController,
                decoration: _inputDecoration('예시').copyWith(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: AppColors.border, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            _buildLabeledField('생년월일',
                TextField(
                    controller: birthController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('YYYY.MM.DD').copyWith(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppColors.border, width: 2),
                      ),
                    )
                )
            ),
            const SizedBox(height: 16),
            const Text('성별'),
            const SizedBox(height: 8),
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE9E8F1), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGender = '남성';
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedGender == '남성' ? AppColors.main : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text('남성', style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        )),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: double.infinity,
                    color: const Color(0xFFE9E8F1),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGender = '여성';
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: selectedGender == '여성' ? AppColors.main : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text('여성', style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isNextEnabled
                    ? () {
                  context.go('/terms');
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isNextEnabled
                      ? AppColors.main
                      : AppColors.unchecked,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.unchecked,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
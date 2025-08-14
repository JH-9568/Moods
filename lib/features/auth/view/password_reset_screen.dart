import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moods/common/constants/colors.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  int step = 1;
  final TextEditingController emailIdController = TextEditingController();
  final TextEditingController emailDomainController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPwController = TextEditingController();
  final TextEditingController newPwConfirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text('비밀번호 재설정', style: TextStyle(color: AppColors.black)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이메일 인증 후\n재설정이 가능해요',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 28),

            // 이메일 입력
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: emailIdController,
                    decoration: const InputDecoration(hintText: '이메일'),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('@'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: emailDomainController,
                    decoration: const InputDecoration(hintText: '직접입력'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (step == 2 || step == 3) ...[
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  hintText: '인증번호 입력',
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (step == 4) ...[
              TextField(
                controller: newPwController,
                decoration: const InputDecoration(hintText: '새 비밀번호 입력'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPwConfirmController,
                decoration: const InputDecoration(hintText: '비밀번호 확인'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
            ],

            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.main, // 알아서 색 바꿔
              ),
              onPressed: () {
                setState(() {
                  if (step < 4) {
                    step++;
                  } else {
                    // 최종 비번 변경 로직
                    context.go('/start'); // 혹은 로그인 화면으로
                  }
                });
              },
              child: Text(
                step == 1
                    ? '인증번호 요청'
                    : step == 2
                        ? '인증번호 확인'
                        : step == 3
                            ? '인증번호 확인'
                            : '비밀번호 재설정',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/auth/view/start_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:moods/features/auth/controller/auth_controller.dart';
import 'package:moods/common/constants/colors_j.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});
  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 모두 입력하세요.')),
      );
      return;
    }

    await ref.read(authControllerProvider.notifier).login(email, password);
    ref.read(authControllerProvider).whenOrNull(
      error: (err, _) =>
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인 실패: $err'))),
    );
  }

  Future<void> _handleKakaoLogin() async {
    try {
      await ref.read(authControllerProvider.notifier).loginWithKakao();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('카카오 로그인 오류: $e')));
    }
  }

  InputDecoration _fieldDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColorsJ.grayText, fontWeight: FontWeight.w400),
      filled: true,
      fillColor: AppColorsJ.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsJ.gray2, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsJ.gray2, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsJ.gray2, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColorsJ.main1,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 120), // 상단 여백(시안 비율)
                    const Text(
                      'Welcome',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColorsJ.black),
                    ),
                    const SizedBox(height: 8),
                    Image.asset( // ✅ SvgPicture.asset -> Image.asset 으로 변경
                      'assets/fonts/icons/moodslogo.png',
                      width: 148,
                      height: 70,
                    ),
                    const SizedBox(height: 32),

                    // 아이디 / 비밀번호
                    TextField(controller: emailController, decoration: _fieldDeco('아이디')),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _fieldDeco('비밀번호'),
                    ),
                    const SizedBox(height: 18),

                    // 로그인 버튼
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: loginState.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorsJ.main3,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: loginState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('로그인',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                    ),

                    const SizedBox(height: 10), // 로그인 바로 아래
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/reset-password'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          foregroundColor: AppColorsJ.black,
                          overlayColor: Colors.transparent,
                        ),
                        child: const Text(
                          '비밀번호 재설정',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColorsJ.black),
                        ),
                      ),
                    ),

                    // 아래로 밀기
                    const Spacer(),

                    // 회원가입
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => context.push('/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorsJ.main2,
                          foregroundColor: AppColorsJ.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          '회원가입',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColorsJ.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 카카오로 시작하기
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: loginState.isLoading ? null : _handleKakaoLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE812),
                          foregroundColor: AppColorsJ.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 시안 아이콘(svg)
                            SvgPicture.asset(
                              'assets/fonts/icons/kakao.svg', // 프로젝트 상대경로
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '카카오로 시작하기',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColorsJ.black),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 하단 붙이기
                    const SafeArea(top: false, bottom: true, child: SizedBox(height: 55)),
                  ],
                ), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}

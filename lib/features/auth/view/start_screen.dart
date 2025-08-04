import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Text(
                'Welcome',
                style: TextStyle(fontSize: 18, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Moods',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 아이디
              const TextField(
                decoration: InputDecoration(
                  hintText: '아이디',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // 비밀번호
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '비밀번호',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // 로그인 버튼
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/login'); // 실제 로그인 기능 연결 예정
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFC6FA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('로그인'),
                ),
              ),
              const SizedBox(height: 8),

              // 비밀번호 재설정 텍스트
              TextButton(
                onPressed: () {
                  context.go('/reset-password');
                },
                child: const Text(
                  '비밀번호 재설정',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 16),

              // 회원가입 버튼
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/register');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDEFFE),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('회원가입'),
                ),
              ),
              const SizedBox(height: 8),

              // 카카오 로그인 버튼
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.go('/kakao');
                  },
                  icon: const Icon(Icons.chat_bubble, color: Colors.black),
                  label: const Text(
                    '카카오로 바로 시작',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE812),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/features/home/view/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moods/features/auth/controller/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '홈 화면 (임시)',
              style: TextStyle(fontSize: 28, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // 토큰/세션/Prefs 정리
                await ref.read(authControllerProvider.notifier).logout();
                if (!context.mounted) return;
                // 스타트 화면으로 이동
                context.go('/start');
              },
              child: const Text('스타트 화면으로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ lib/features/explore/view/explore_screen.dart
import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ⭐️ Scaffold를 제거하고 바로 콘텐츠 위젯을 반환합니다.
    return const Center(
      child: Text(
        '공간 추천 화면',
        style: TextStyle(fontSize: 24, color: Colors.purple), // 구분을 위해 색상 변경
      ),
    );
  }
}

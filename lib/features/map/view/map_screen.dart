import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ⭐️ Scaffold를 제거하고 바로 콘텐츠 위젯을 반환합니다.
    return const Center(
      child: Text(
        '지도 화면',
        style: TextStyle(fontSize: 24, color: Colors.green), // 구분을 위해 색상 변경
      ),
    );
  }
}

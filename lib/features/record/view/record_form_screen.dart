// (옵션) 따로 폼 화면이 필요하면 쓰고, 아니면 유지만.
import 'package:flutter/material.dart';

class RecordFormScreen extends StatelessWidget {
  const RecordFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('추후 기록 폼(메모 등) 필요 시 구현')),
    );
  }
}

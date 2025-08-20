// 라우팅 편의 Wrapper (필요 없으면 삭제해도 됨)
import 'package:flutter/material.dart';
import 'package:moods/features/record/controller/record_controller.dart';
import 'package:moods/features/record/view/record_timer_screen.dart';

class RecordScreen extends StatelessWidget {
  final StartArgs args;
  const RecordScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return RecordTimerScreen(startArgs: args);
  }
}

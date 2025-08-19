import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GlobalBackButton extends StatelessWidget {
  final Color? color;

  const GlobalBackButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color ?? Colors.black),
      onPressed: () {
        try {
          // GoRouter 기반 pop이 불가능한 경우를 대비
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else if (context.canPop()) {
            context.pop();
          } else {
            context.go('/start'); // fallback
          }
        } catch (e) {
          // 예외 처리: 그래도 에러 나면 fallback
          context.go('/start');
        }
      },
    );
  }
}

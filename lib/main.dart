import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moods/routes/app_router.dart';
import 'common/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router, 
      theme: appTheme,
    );
  }
}

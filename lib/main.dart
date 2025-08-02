import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moods/routes/app_router.dart';
import 'common/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ));
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

// ✅ lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

// 공통 위젯
import '../common/widgets/custom_bottom_nav.dart';
import '../common/widgets/custom_app_bar.dart'; // ✅ 앱바 추가

// 화면
import '../features/home/view/home_screen.dart';
import '../features/explore/view/explore_screen.dart';
import '../features/map/view/map_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/home',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          debugPrint('ShellRoute builder called. Current path: ${state.uri}');

          return Scaffold(
            extendBodyBehindAppBar: true, // ⭐️ 이 속성을 추가합니다.
            appBar: const CustomAppBar(), // ✅ 고정 AppBar
            body: child, // 현재 활성 화면 (GoRoute 하위)
            bottomNavigationBar: const CustomBottomNav(), // 고정 BottomNav
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) {
              debugPrint('Navigating to HomeScreen');
              return const HomeScreen();
            },
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) {
              debugPrint('Navigating to ExploreScreen');
              return const ExploreScreen();
            },
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) {
              debugPrint('Navigating to MapScreen');
              return const MapScreen();
            },
          ),
        ],
      ),
    ],
  );
}

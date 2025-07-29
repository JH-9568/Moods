// ✅ lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:moods/features/auth/view/Terms_Agreement_Screen.dart';
import 'package:moods/features/auth/view/complete_sign_up_screen.dart';
import 'package:moods/features/auth/view/kakao_sign_up.dart';
import 'package:moods/features/auth/view/register_screen.dart';
import 'package:moods/features/auth/view/start_screen.dart';

// 공통 위젯
import '../common/widgets/custom_bottom_nav.dart';
import '../common/widgets/custom_app_bar.dart'; // ✅ 앱바 추가

// 화면
import '../features/home/view/home_screen.dart';
import '../features/explore/view/explore_screen.dart';
import '../features/map/view/map_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/terms',
    routes: [

      // ✅ 로그인/회원가입 흐름
      GoRoute(
        path: '/start',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/kakao',
        builder: (context, state) => const AdditionalInfoScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsAgreementScreen(),
      ),
      GoRoute(
        path: '/complete',
        builder: (context, state) => const SignUpCompleteScreen(),
      ),

      // ✅ 메인 앱 구조 (ShellRoute로 감싸기)
      ShellRoute(
        builder: (context, state, child) => Scaffold(
          extendBodyBehindAppBar: true,
          appBar: const CustomAppBar(),
          body: child,
          bottomNavigationBar: const CustomBottomNav(),
        ),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
        ],
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ✅ 로그인/회원가입 관련 화면
import 'package:moods/features/auth/view/start_screen.dart';
import 'package:moods/features/auth/view/register_screen.dart';
import 'package:moods/features/auth/view/kakao_sign_up.dart';
import 'package:moods/features/auth/view/terms_agreement_screen.dart';
import 'package:moods/features/auth/view/complete_sign_up_screen.dart';

// ✅ 메인 화면들
import 'package:moods/features/home/view/home_screen.dart';
import 'package:moods/features/explore/view/explore_screen.dart';
import 'package:moods/features/map/view/map_screen.dart';

// ✅ 공통 위젯
import 'package:moods/common/widgets/custom_app_bar.dart';
import 'package:moods/common/widgets/custom_bottom_nav.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/start', // 앱 첫 진입 시 시작화면
    routes: [

      // ────────────── 로그인/회원가입 ──────────────
      GoRoute(
        path: '/start',
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: '/register', // 일반 회원가입 입력
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/kakao', // 카카오 로그인 후 추가 정보 입력
        builder: (context, state) => const AdditionalInfoScreen(),
      ),
      GoRoute(
        path: '/terms', // 약관 동의 화면
        builder: (context, state) => const TermsAgreementScreen(),
      ),
      GoRoute(
        path: '/complete', // 회원가입 완료 화면
        builder: (context, state) => const SignUpCompleteScreen(),
      ),
      

      // ────────────── 메인 앱 (하단 네비 포함) ──────────────
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

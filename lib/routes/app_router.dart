import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ✅ 로그인/회원가입 관련 화면
import 'package:moods/features/auth/view/start_screen.dart';
import 'package:moods/features/auth/view/register_screen.dart';
import 'package:moods/features/auth/view/kakao_sign_up.dart';
import 'package:moods/features/auth/view/terms_agreement_screen.dart';
import 'package:moods/features/auth/view/complete_sign_up_screen.dart';
import 'package:moods/features/auth/view/password_reset_screen.dart'; // ⬅️ 추가됨

// ✅ 메인 화면들
import 'package:moods/features/home/view/home_screen.dart';
import 'package:moods/features/explore/view/explore_screen.dart';
import 'package:moods/features/map/view/map_screen.dart';

// ✅ 공통 위젯
import 'package:moods/common/widgets/custom_app_bar.dart';
import 'package:moods/common/widgets/custom_bottom_nav.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/start',
    routes: [

      // ────────────── 로그인/회원가입 ──────────────
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
      GoRoute(
        path: '/reset-password', // ⬅️ 여기 새로 추가됨
        builder: (context, state) => const PasswordResetScreen(),
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

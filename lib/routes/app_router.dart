// routes/app_router.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moods/features/auth/view/start_screen.dart';
import 'package:moods/features/auth/view/register_screen.dart';
import 'package:moods/features/auth/view/kakao_sign_up.dart';
import 'package:moods/features/auth/view/terms_agreement_screen.dart';
import 'package:moods/features/auth/view/complete_sign_up_screen.dart';
import 'package:moods/features/auth/view/password_reset_screen.dart';
import 'package:moods/features/home/view/home_screen.dart';
import 'package:moods/features/explore/view/explore_screen.dart';
import 'package:moods/features/map/view/map_screen.dart';
import 'package:moods/common/widgets/custom_app_bar.dart';
import 'package:moods/common/widgets/custom_bottom_nav.dart';
// RecordTimerScreen
import 'package:moods/features/record/view/record_timer_screen.dart';

// StartArgs
import 'package:moods/features/record/controller/record_controller.dart';

class RouterPing extends ChangeNotifier {
  void ping() => notifyListeners();
}
final routerPing = RouterPing();

class GoRouterRefresh extends ChangeNotifier {
  late final StreamSubscription _sub;
  GoRouterRefresh(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// 세션 캐시
String? _cachedUid;
bool? _cachedProfileFilled;

GoRouter createAppRouter() {
  final supa = Supabase.instance.client;
  final authStream = supa.auth.onAuthStateChange;

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: Listenable.merge([
      GoRouterRefresh(authStream),
      routerPing,
    ]),
    redirect: (context, state) async {
      final supa = Supabase.instance.client;
      final path = state.uri.path;
      final scheme = state.uri.scheme;

      // 0) 딥링크 콜백은 통과
       if (scheme == 'moods') {
    return '/start'; // 또는 '/home' 원하는 위치
  }

      // 1) 온보딩 화면은 세션 여부와 무관하게 항상 통과
      const onboardingPages = {'/kakao', '/terms', '/complete'};
      if (onboardingPages.contains(path)) {
        if (path == '/complete') _cachedProfileFilled = null; // 캐시 초기화
        return null;
      }

      // 2) 로그인 게이트
      final prefs       = await SharedPreferences.getInstance();
      final customToken = prefs.getString('access_token');
      final session     = supa.auth.currentSession;
      final hasSupa     = session != null;
      final hasCustom   = (customToken != null && customToken.isNotEmpty);
      final loggedIn    = hasSupa || hasCustom;

      const authPages = {'/start', '/register', '/reset-password'};

      // ── 비로그인
      if (!loggedIn) {
        _cachedUid = null;
        _cachedProfileFilled = null;
        return authPages.contains(path) ? null : '/start';
      }

      // ── 로그인됨 (카카오/이메일 공통)
      if (hasSupa) {
        final uid = session!.user.id;

        if (_cachedUid != uid) {
          _cachedUid = uid;
          _cachedProfileFilled = null;
        }

        bool? filled = _cachedProfileFilled;
        if (filled == null) {
          try {
            final row = await supa
                .from('users')
                // ⚠️ 이메일 필수 체크 제외(카카오에서 없을 수 있음)
                .select('nickname, birthday, gender,email')
                .eq('id', uid)
                .maybeSingle();

            final filled = row != null &&
  (row['nickname'] ?? '').toString().isNotEmpty &&
  row['birthday'] != null &&
  row['gender'] != null &&
  (row['email'] ?? '').toString().isNotEmpty;   

            _cachedProfileFilled = filled;
          } catch (_) {
            _cachedProfileFilled = filled = false;
          }
        }

        if (filled == false && path != '/kakao') return '/kakao';

        // 약관 동의 여부
        final termsDone = prefs.getBool('terms_done') ?? false;
        if (!termsDone && path != '/terms') return '/terms';
      } else {
        // 커스텀 토큰만 있는 경우(이메일/비번 로그인)
        final termsDone = prefs.getBool('terms_done') ?? false;
        if (!termsDone && path != '/terms') return '/terms';
      }

      // 로그인 상태에서 인증/가입 화면 접근 시 홈으로
      if (authPages.contains(path)) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/start', builder: (_, __) => const StartScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/kakao', builder: (_, __) => const AdditionalInfoScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsAgreementScreen()),
      GoRoute(path: '/complete', builder: (_, __) => const SignUpCompleteScreen()),
      GoRoute(path: '/reset-password', builder: (_, __) => const PasswordResetScreen()),
      GoRoute(
  path: '/record',
  builder: (context, state) {
    final args = state.extra as StartArgs;
    return RecordTimerScreen(startArgs: args);
  },
),
      ShellRoute(
        builder: (_, __, child) => Scaffold(
          extendBodyBehindAppBar: true,
          appBar: const CustomAppBar(),
          body: child,
          bottomNavigationBar: const CustomBottomNav(),
        ),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/explore', builder: (_, __) => const ExploreScreen()),
          GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
        ],
      ),
    ],
  );
}

// routes/app_router.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/my_page/my_page_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moods/features/my_page/user_profile/user_profile_controller.dart';
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
import 'package:moods/features/record/view/record_timer_screen.dart';
import 'package:moods/features/record/view/record_card_preview.dart';
import 'package:moods/features/record/controller/record_controller.dart';
import 'package:moods/features/record/view/record_finalize_step1.dart';
import 'package:moods/features/my_page/edit_profile/edit_profile_screen.dart';
import 'package:moods/features/calendar/widget/calendar_widget.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/widgets/back_button.dart';
import 'package:moods/providers.dart';

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
    initialLocation: '/start',
    refreshListenable: Listenable.merge([
      GoRouterRefresh(authStream),
      routerPing,
    ]),
    redirect: (context, state) async {
      final supa = Supabase.instance.client;
      final path = state.uri.path;

      // 0) 딥링크 콜백은 통과 (원하면 /home 등으로 바꿔도 됨)
      if (state.uri.scheme == 'moods') {
        return '/start';
      }

      // 1) 온보딩 화면은 항상 통과
      const onboardingPages = {'/kakao', '/terms', '/complete'};
      if (onboardingPages.contains(path)) {
        if (path == '/complete') _cachedProfileFilled = null;
        return null;
      }

      // 2) 로그인 게이트
      final prefs = await SharedPreferences.getInstance();
      final spToken = prefs.getString('access_token');
      final hasSp = spToken != null && spToken.isNotEmpty;

      final session = supa.auth.currentSession;
      final hasSupa = session != null;

      final loggedIn = hasSp || hasSupa;
      const authPages = {'/start', '/register', '/reset-password'};

      if (!loggedIn) {
        _cachedUid = null;
        _cachedProfileFilled = null;
        return authPages.contains(path) ? null : '/start';
      }

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
                .select('nickname, birthday, gender, email')
                .eq('id', uid)
                .maybeSingle();

            filled =
                row != null &&
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

        final termsDone = prefs.getBool('terms_done') ?? false;
        if (!termsDone && path != '/terms') return '/terms';
      } else {
        final termsDone = prefs.getBool('terms_done') ?? false;
        if (!termsDone && path != '/terms') return '/terms';
      }

      if (authPages.contains(path)) return '/home';
      return null;
    },
    routes: [
      // 인증/온보딩 라우트(기존 builder 유지)
      GoRoute(path: '/start', builder: (_, __) => const StartScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/kakao', builder: (_, __) => const AdditionalInfoScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsAgreementScreen()),
      GoRoute(
        path: '/complete',
        builder: (_, __) => const SignUpCompleteScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, __) => const PasswordResetScreen(),
      ),
      GoRoute(
        path: '/record/preview',
        builder: (_, state) {
          final data = state.extra as RecordCardData;
          return RecordCardPreviewScreen(data: data);
        },
      ),
      GoRoute(
        path: '/record/finalize_step1',
        builder: (_, __) => const FinalizeStep1Screen(),
      ),
      GoRoute(
        path: '/record',
        builder: (context, state) {
          final args = state.extra as StartArgs;
          return RecordTimerScreen(startArgs: args);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) {
          // MyPage에서 전달한 초기값 (없어도 동작)
          final extra = (state.extra is Map) ? state.extra as Map : const {};
          final nickname = extra['nickname'] as String?;
          final birthday =
              extra['birthday'] as String?; // 'YYYY-MM-DD' or 'YYYY.MM.DD'
          final gender = extra['gender'] as String?; // 'm'|'f' or '남성'|'여성'

          return EditProfileScreen(
            initialNickname: nickname,
            initialBirthday: birthday,
            initialGender: gender,
            onSuccessRoute: '/profile',
          );
        },
        onExit: (context, state) {
          // 프로필 수정 후 '/profile'로 돌아갈 때 userProfileControllerProvider를 무효화
          // 이렇게 하면 MyPageWidget이 최신 프로필 정보를 다시 불러옵니다.
          final container = ProviderScope.containerOf(context);
          container.invalidate(userProfileControllerProvider);
          print('🔄 Invalidated userProfileControllerProvider on exit from edit profile.');
          return true;
        },
      ),

      // 탭 구조: ShellRoute
      ShellRoute(
        builder: (context, state, child) {
          final String path = state.uri.path; // 예: '/profile', '/home' ...
          final bool isProfile =
              path == '/profile' || path.startsWith('/profile/');

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: isProfile ? null : const CustomAppBar(),
            body: child,
            bottomNavigationBar: const CustomBottomNav(),
          );
        },
        // 탭 4개는 모두 NoTransitionPage로: 전환 애니메이션 제거
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (_, __) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/explore',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ExploreScreen()),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (_, __) => const NoTransitionPage(child: MapScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: MyPageWidget()),
          ),
          GoRoute(
            path: '/profile/calendar',
            builder: (context, state) {
              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  backgroundColor: AppColors.sub,
                  elevation: 0,
                  leading: const GlobalBackButton(color: Colors.white),
                  centerTitle: true,
                  title: const Text(
                    '기록 캘린더',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                body: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CalendarWidget(), // 기존 ExploreScreen에서 쓰던 위젯 그대로
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}

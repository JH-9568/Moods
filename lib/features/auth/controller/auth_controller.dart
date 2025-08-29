// lib/features/auth/controller/auth_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart'; // debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moods/features/auth/service/auth_service.dart';
import 'package:moods/routes/app_router.dart' show routerPing;
import 'package:moods/providers.dart';

/// =====================
/// Providers
/// =====================
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final svc = ref.read(authServiceProvider);
  return AuthController(ref, svc);
});

/// =====================
/// Controller
/// =====================
class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final AuthService _authService;

  StreamSubscription<AuthState>? _sub;
  Timer? _refreshTimer; // ⏰ 만료 전 자동 갱신 타이머

  AuthController(this.ref, this._authService)
    : super(const AsyncValue.data(null)) {
  // ✅ build(초기화) 중에 다른 provider 상태를 건드리지 않도록, 다음 마이크로태스크로 미룸
  Future.microtask(() {
    _initAuthListener();
    _syncCurrentSessionOnAppStart();
  });
}


  // ---- 앱 시작 시 저장된 세션 동기화
  void _syncCurrentSessionOnAppStart() {
    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession != null) {
      ref.read(authTokenProvider.notifier).state = currentSession.accessToken;
      ref.read(authUserProvider.notifier).state = currentSession.user.toJson();
      debugPrint('✅ App Start: Restored session');

      // ⏰ 앱 시작할 때도 갱신 타이머 설정
      _scheduleRefreshFrom(currentSession);
    } else {
      debugPrint('🤔 App Start: No session');
    }
  }

  // ---- Supabase 인증 상태 리스너
  void _initAuthListener() {
    _sub?.cancel();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      ref.read(authTokenProvider.notifier).state = session?.accessToken;
      ref.read(authUserProvider.notifier).state = session?.user.toJson();
      ref.read(authLastEventProvider.notifier).state = event;

      debugPrint('✅ Auth state: $event');

      // 로그인/갱신 시 갱신 타이머 재설정, 로그아웃 시 타이머 해제
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        _scheduleRefreshFrom(session);
      } else if (event == AuthChangeEvent.signedOut) {
        _cancelRefreshTimer();
      }

      // 로그인 직후 사용자 row 보장
      if (event == AuthChangeEvent.signedIn) {
        _authService.ensureUserRow().catchError((e) {
          debugPrint('[auth] ensureUserRow failed: $e');
        });
      }
    });
  }

  // ---- 만료 45초 전에 refreshSession() 실행
  void _scheduleRefreshFrom(Session? s) {
    _cancelRefreshTimer();
    if (s == null) return;

    // Supabase가 주는 남은 수명(초). null이면 3600초(60분)로 가정.
    int ttlSec = s.expiresIn ?? 3600;
    // 안전하게 45초 전에 실행
    int lead = ttlSec - 45;
    if (lead <= 0) lead = 1;

    final delay = Duration(seconds: lead);
    debugPrint('⏰ schedule token refresh in ${delay.inSeconds}s');

    _refreshTimer = Timer(delay, () async {
      try {
        await Supabase.instance.client.auth.refreshSession();
        debugPrint('🔄 token refresh triggered by timer');
      } catch (e) {
        debugPrint('❗ token refresh failed: $e');
      }
    });
  }

  void _cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _cancelRefreshTimer();
    super.dispose();
  }

  // -------------------------------
  // 이메일/비번 로그인 (백엔드)
  // -------------------------------
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final dynamic res = await _authService.login(email, password);

      final String? token = _extractToken(res);
      if (token != null && token.isNotEmpty) {
        ref.read(authTokenProvider.notifier).state = token;
        debugPrint('✅ Custom login: token set');
      } else {
        debugPrint('⚠️ Custom login returned empty token (res=$res)');
      }

      routerPing.ping();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      state = AsyncValue.error(e, st);
    }
  }

  // -------------------------------
  // 카카오 로그인 (Supabase OAuth) — 그대로 둠
  // -------------------------------
  Future<void> loginWithKakao() async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      await _authService.loginWithKakao();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      state = AsyncValue.error(e, st);
    }
  }

  // -------------------------------
  // 로그아웃
  // -------------------------------
  Future<void> logout() async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      routerPing.ping();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      state = AsyncValue.error(e, st);
    }
  }

  // -------------------------------
  // 비밀번호 재설정
  // -------------------------------
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
    required String code,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.resetPassword(
        email: email,
        newPassword: newPassword,
        code: code,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // -------------------------------
  // 회원가입 흐름
  // -------------------------------
  Future<String?> requestInitialVerification({
    required String email,
    required String password,
    required String nickname,
    required String birth,
    required String gender,
  }) async {
    state = const AsyncValue.loading();
    try {
      final uuid = await _authService.requestInitialVerification(
        email: email,
        password: password,
        nickname: nickname,
        birth: birth,
        gender: gender,
      );
      state = const AsyncValue.data(null);
      return uuid;
    } catch (e, st) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> checkEmailVerified(String uuid) async {
    try {
      return await _authService.checkEmailVerified(uuid);
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      return false;
    }
  }

  Future<String?> sendInitialVerificationEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      final uuid = await _authService.sendInitialVerificationEmail(email);
      state = const AsyncValue.data(null);
      return uuid;
    } catch (e, st) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> completeEmailSignUp({
    required String userId,
    required String email,
    required String password,
    required String nickname,
    required String birth,
    required String gender,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.completeEmailSignUp(
        userId: userId,
        email: email,
        password: password,
        nickname: nickname,
        birth: birth,
        gender: gender,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authService.sendVerificationCode(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // -------------------------------
  // 온보딩 완료
  // -------------------------------
  Future<bool> completeOnboarding({
    required String nickname,
    required String genderLetter,
    required String birthday,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.patchUserInfo(
        nickname: nickname,
        genderLetter: genderLetter,
        birthday: birthday,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      state = AsyncValue.error(e, st);
    }
  }

  // ==========================
  // ⬇️ 반환 타입과 무관하게 토큰만 추출
  // ==========================
  String? _extractToken(dynamic res) {
    if (res == null) return null;

    // 1) String 그대로
    if (res is String) return res;

    // 2) Supabase 타입
    if (res is Session) return res.accessToken;
    if (res is AuthResponse) return res.session?.accessToken;

    // 3) Map(JSON) 계열
    if (res is Map) {
      final s = res['session'];
      if (s is Map && s['access_token'] is String) {
        return s['access_token'] as String;
      }
      if (res['access_token'] is String) {
        return res['access_token'] as String;
      }
      final d = res['data'];
      if (d is Map && d['access_token'] is String) {
        return d['access_token'] as String;
      }
    }
    return null;
  }
}

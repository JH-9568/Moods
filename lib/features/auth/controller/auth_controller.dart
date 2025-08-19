import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moods/features/auth/service/auth_service.dart';
import 'package:moods/common/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moods/routes/app_router.dart' show routerPing;

import 'package:http/http.dart' as http;
import 'dart:convert';

/// =====================
/// Providers
/// =====================
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authTokenProvider = StateProvider<String?>((ref) => null);
final authUserProvider  = StateProvider<Map<String, dynamic>?>((ref) => null);

final authLastEventProvider = StateProvider<AuthChangeEvent?>((ref) => null);
final authErrorProvider     = StateProvider<String?>((ref) => null);

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

  AuthController(this.ref, this._authService)
      : super(const AsyncValue.data(null)) {
    Future.microtask(() {
      if (!mounted) return;
      _initAuthListener();
      _syncCurrentSession();
    });
  }

  void _initAuthListener() {
    _sub?.cancel();
    final supa = Supabase.instance.client;

    _sub = supa.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;

      final event   = data.event;
      final session = data.session;
      ref.read(authLastEventProvider.notifier).state = event;
      debugPrint('[auth] event=$event, user=${session?.user.id}');

      switch (event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
        case AuthChangeEvent.userUpdated:
          final access = session?.accessToken;
          final user   = session?.user;
          ref.read(authTokenProvider.notifier).state = access;
          ref.read(authUserProvider.notifier).state  = user?.toJson();

          try {
            await _authService.ensureUserRow();
            unawaited(_authService.syncEmailIntoUsers());
          } catch (e) {
            debugPrint('[auth] ensureUserRow failed: $e');
          }
          break;

        case AuthChangeEvent.signedOut:
          ref.read(authTokenProvider.notifier).state = null;
          ref.read(authUserProvider.notifier).state  = null;
          break;

        default:
          break;
      }
    });
  }

  void _syncCurrentSession() {
    final current = Supabase.instance.client.auth.currentSession;
    if (current != null) {
      ref.read(authTokenProvider.notifier).state = current.accessToken;
      ref.read(authUserProvider.notifier).state  = current.user.toJson();
    } else {
      ref.read(authTokenProvider.notifier).state = null;
      ref.read(authUserProvider.notifier).state  = null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // -------------------------------
  // 이메일/비밀번호 로그인 (커스텀 백엔드)
  // -------------------------------
  Future<void> login(String email, String password) async {
  state = const AsyncValue.loading();
  try {
    final session = await _authService.login(email, password);

    final token = session['access_token'] as String?;
    final user  = session['user'] as Map<String, dynamic>?;

    if (token == null || token.isEmpty) {
      throw Exception('로그인 응답에 access_token이 없습니다.');
    }

    // 상태 보관
    ref.read(authTokenProvider.notifier).state = token;
    ref.read(authUserProvider.notifier).state  = user;

    // 로컬 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);

    // 🔔 라우터 리프레시 트리거
    routerPing.ping();

    state = const AsyncValue.data(null);
  } catch (e, st) {
    ref.read(authErrorProvider.notifier).state = e.toString();
    state = AsyncValue.error(e, st);
  }
}



  // -------------------------------
  // 카카오 로그인 (Supabase OAuth)
  // -------------------------------
 Future<void> loginWithKakao() async {
  if (state.isLoading) return;
  state = const AsyncValue.loading();
  try {
    // 외부 OAuth 흐름은 리스너(event)로 처리하니까 기다리지 마
    unawaited(_authService.loginWithKakao());
  } catch (e, st) {
    ref.read(authErrorProvider.notifier).state = e.toString();
    state = AsyncValue.error(e, st);
    return;
  }
  // 바로 로딩 풀어줘야 버튼/화면 안 얼어붙음
  state = const AsyncValue.data(null);
}

  // -------------------------------
  // 로그아웃
  // -------------------------------
 Future<void> logout() async {
  state = const AsyncValue.loading();
  try {
    await _authService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');

    ref.read(authTokenProvider.notifier).state = null;
    ref.read(authUserProvider.notifier).state  = null;

    // 🔔 라우터 리프레시
    routerPing.ping();

    state = const AsyncValue.data(null);
  } catch (e, st) {
    ref.read(authErrorProvider.notifier).state = e.toString();
    state = AsyncValue.error(e, st);
  }
}


  // 비밀번호재설정
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
  // 회원가입 관련 위임
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
  } catch (e, st) {
    ref.read(authErrorProvider.notifier).state = e.toString();
    return false;
  }
}



  /// 이메일만으로 최초 인증 메일 전송 (옵션 유지)
 Future<String?> sendInitialVerificationEmail(String email) async {
  state = const AsyncValue.loading();
  try {
    final uuid = await _authService.sendInitialVerificationEmail(email);
    state = const AsyncValue.data(null);
    return uuid; // ← 이걸 뷰에서 받아서 _signupUuid에 저장
  } catch (e, st) {
    ref.read(authErrorProvider.notifier).state = e.toString();
    state = AsyncValue.error(e, st);
    return null;
  }
}

// 회원가입쪽
Future<bool> completeEmailSignUp({
  required String userId,   // ★ uuid 필수
  required String email,
  required String password,
  required String nickname,
  required String birth,    // YYYY-MM-DD
  required String gender,   // 'm' | 'f'
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



  /// 인증 메일 재전송
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
  // 온보딩 완료: 백엔드 PATCH만 호출
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
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // (기존 사용: 남겨둠, 더이상 저장엔 안씀)
import 'package:moods/main.dart';
import 'package:moods/features/auth/service/auth_service.dart';
import 'package:moods/features/auth/service/token_storage.dart'; // ⬅️ 추가
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

  // ⬇️ SecureStorage 래퍼
 late final TokenStorage _storage;

  StreamSubscription<AuthState>? _sub;
  Timer? _refreshTimer; // Supabase OAuth용

  AuthController(this.ref, this._authService)
      : super(const AsyncValue.data(null)) {
    _storage = ref.read(tokenStorageProvider);

    Future.microtask(() async {
      _initAuthListener();                  // Supabase OAuth 이벤트
      await _syncCurrentSessionOnAppStart(); // 커스텀 토큰 복구
    });
  }

  // ===============================
  // JWT 만료 체크 (커스텀 토큰용)
  // ===============================
  bool _isJwtExpired(String token, {int leewaySec = 30}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      var b64 = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (b64.length % 4 != 0) b64 += '=';
      final payload = jsonDecode(utf8.decode(base64Url.decode(b64)));
      final exp = payload['exp'];
      if (exp is! num) return true;
      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      return nowSec >= (exp.toInt() - leewaySec);
    } catch (_) {
      return true;
    }
  }

  // ---- 앱 시작 시 저장된 세션/토큰 동기화
  Future<void> _syncCurrentSessionOnAppStart() async {
    // 1) Supabase 세션(카카오 OAuth) 우선
    final supa = Supabase.instance.client.auth.currentSession;
    if (supa != null && supa.accessToken.isNotEmpty) {
      ref.read(authTokenProvider.notifier).state = supa.accessToken;
      ref.read(authUserProvider.notifier).state = supa.user.toJson();
      debugPrint('✅ App Start: Restored Supabase session');
      _scheduleRefreshFrom(supa);
      return;
    }

    // 2) 내 백엔드 JWT (SecureStorage) 복구
    final access = await _storage.readAccessToken();
    if (access != null && access.isNotEmpty && !_isJwtExpired(access)) {
      ref.read(authTokenProvider.notifier).state = access;
      ref.read(authUserProvider.notifier).state = null; // 서버 호출 시 채워짐
      debugPrint('✅ App Start: Restored backend access token from storage');
      // Supabase 타이머는 없음(우리 http client가 401 자동 처리)
    } else {
      debugPrint('🤔 App Start: No valid token found');
    }
  }

  // ---- Supabase 인증 상태 리스너 (카카오 OAuth용)
  void _initAuthListener() {
    _sub?.cancel();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.initialSession &&
          (session == null || session.accessToken.isEmpty)) {
        debugPrint(
            '⏭️ Auth state: initialSession(null) — ignore (keep existing token)');
        return;
      }

      ref.read(authTokenProvider.notifier).state = session?.accessToken;
      ref.read(authUserProvider.notifier).state = session?.user.toJson();
      ref.read(authLastEventProvider.notifier).state = event;

      debugPrint('✅ Auth state: $event  (hasSession=${session != null})');

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        _scheduleRefreshFrom(session);
      } else if (event == AuthChangeEvent.signedOut) {
        _cancelRefreshTimer();
        // Supabase 로그아웃 시 우리 저장소도 비워둠(혼선 방지)
        _storage.clearAll();
      }

      if (event == AuthChangeEvent.signedIn) {
        _authService.ensureUserRow().catchError((e) {
          debugPrint('[auth] ensureUserRow failed: $e');
        });
      }
    });
  }

  // ---- Supabase 전용: 만료 45초 전에 refreshSession()
  void _scheduleRefreshFrom(Session? s) {
    _cancelRefreshTimer();
    if (s == null) return;

    int ttlSec = s.expiresIn ?? 3600;
    int lead = ttlSec - 45;
    if (lead <= 0) lead = 1;

    final delay = Duration(seconds: lead);
    debugPrint('⏰ schedule supabase token refresh in ${delay.inSeconds}s');

    _refreshTimer = Timer(delay, () async {
      try {
        await Supabase.instance.client.auth.refreshSession();
        debugPrint('🔄 supabase token refresh by timer');
      } catch (e) {
        debugPrint('❗ supabase token refresh failed: $e');
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
  // 이메일/비번 로그인 (우리 백엔드)
  // -------------------------------
  Future<void> login(String email, String password) async {
  if (state.isLoading) return;
  state = const AsyncValue.loading();

  try {
    // 로그인은 항상 Map을 반환
    final Map<String, dynamic> result = await _authService.login(email, password);

    String? access;
    String? refresh;

    final m = result;

    // 1) session 래핑 형태
    if (m['session'] is Map) {
      final sess = Map<String, dynamic>.from(m['session'] as Map);
      access  = (sess['access_token'] ?? sess['accessToken'])?.toString();
      refresh = (sess['refresh_token'] ?? sess['refreshToken'])?.toString();
    } else {
      // 2) 최상위 키
      access  = (m['access_token'] ?? m['accessToken'] ?? m['token'])?.toString();
      refresh = (m['refresh_token'] ?? m['refreshToken'])?.toString();

      // 3) 혹시 data 래핑돼 온 경우까지 방어
      if ((access == null || access.isEmpty) && m['data'] is Map) {
        final d = Map<String, dynamic>.from(m['data'] as Map);
        access  = (d['access_token'] ?? d['accessToken'] ?? d['token'])?.toString();
        refresh = (d['refresh_token'] ?? d['refreshToken'])?.toString();
      }
    }

    if (access == null || access.isEmpty) {
      throw Exception('로그인 성공 응답에 access_token이 없습니다.');
    }

    // 저장/주입 (TokenStorage 사용)
    await _storage.saveAccessToken(access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.saveRefreshToken(refresh);
    }
    await _storage.saveLoginPayload({
      'type': 'password',
      'email': email,
      'password': password,        
    });

    ref.read(authTokenProvider.notifier).state = access;
    ref.read(routerPingProvider).ping();
    state = const AsyncValue.data(null);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    rethrow;
  }
}

  // -------------------------------
  // 카카오 로그인 (Supabase OAuth)
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
    state = const AsyncValue.loading();
    try {
      await _authService.signOut(); // supabase & prefs 정리
      await _storage.clearAll();    // secure storage 정리

      // Provider는 supabase listener가 지워주지만 혹시 모를 잔여치우기
      ref.read(authTokenProvider.notifier).state = null;
      ref.read(authUserProvider.notifier).state = null;

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
  // 회원가입/인증 흐름 (변경 없음)
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
}

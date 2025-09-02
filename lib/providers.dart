// lib/app_providers.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/service/auth_service.dart';
import 'features/record/service/record_service.dart';

// ============ 공통: JWT 만료 체크 ============
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

String? _pickValid(String? t) =>
    (t != null && t.isNotEmpty && !_isJwtExpired(t)) ? t : null;

// -----------------------------
// Auth
// -----------------------------

/// 인증 서비스
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// 앱 시작 시점의 초기 토큰 (Supabase 초기화 전일 수도 있으니 try-catch)
final initialTokenProvider = Provider<String?>((ref) {
  try {
    final t = Supabase.instance.client.auth.currentSession?.accessToken;
    return _pickValid(t);
  } catch (_) {
    return null;
  }
});

/// 현재 액세스 토큰(실시간).
/// - 앱 시작 시 initialTokenProvider로 초기화
/// - onAuthStateChange 리스너(앱 진입 코드)에서 갱신
final authTokenProvider = StateProvider<String?>(
  (ref) => ref.read(initialTokenProvider),
);

/// 부가 상태들
final authUserProvider        = StateProvider<Map<String, dynamic>?>((ref) => null);
final authErrorProvider       = StateProvider<String?>((ref) => null);
final authLastEventProvider   = StateProvider<AuthChangeEvent?>((ref) => null);

/// 필요 시 직접 클라이언트 접근용
final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

// -----------------------------
// Record
// -----------------------------

/// RecordService
///
/// ✅ 매 요청 시점에 최신 토큰을 읽어서 Authorization 헤더를 구성.
/// 우선순위:
///  1) Supabase 현재 세션(accessToken) — 만료 X
///  2) authTokenProvider 상태 — 만료 X
///  3) (옵션) SharedPreferences('access_token') — 만료 X
///  4) 없으면 "" 반환 → Authorization 헤더 생략
final recordServiceProvider = Provider<RecordService>((ref) {
  return RecordService(
    jwtProvider: () {
      String? token;

      // 1) Supabase 현재 세션
      try {
        token = _pickValid(
          Supabase.instance.client.auth.currentSession?.accessToken,
        );
      } catch (_) {
        token = null;
      }

      // 2) authTokenProvider
      token ??= _pickValid(ref.read(authTokenProvider));

      // 3) SharedPreferences (앱에 저장해 둔 토큰이 있을 때)
      if (token == null) {
        try {
          // 동기 호출 불가 → 간단 캐시용으로만 사용 (없으면 무시)
          // 주의: 실제 비동기 접근은 서비스/컨트롤러 단계가 더 적절하지만,
          // 여기선 최후의 보루로 한 번 더 시도.
          final prefs = SharedPreferences.getInstance();
          // getInstance는 Future지만 여기서 기다릴 수 없으므로
          // jwtProvider는 싱크 함수여야 해 → fallback은 컨트롤러의 start에서 해주세요.
          // (컨트롤러에서 prefs 복구 로직 이미 가지고 있으면 이 블럭은 사실상 패스)
        } catch (_) {}
      }

      // 4) 빈 문자열이면 Authorization 미포함
      return (token == null || token.isEmpty) ? '' : 'Bearer $token';
    },
  );
});

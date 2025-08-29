library app_providers;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/service/auth_service.dart';
import 'features/record/service/record_service.dart';

// -----------------------------
// Auth
// -----------------------------

/// 인증 서비스
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// 앱 시작 시점의 초기 토큰 (절대 throw 금지)
final initialTokenProvider = Provider<String?>((ref) {
  // Supabase 초기화 전일 수도 있으니 try-catch로 안전 가드
  try {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  } catch (_) {
    return null;
  }
});

/// 현재 액세스 토큰(실시간). 초기값은 initialTokenProvider에서 읽음.
/// 이후 onAuthStateChange 등에서 갱신됨.
final authTokenProvider = StateProvider<String?>(
  (ref) => ref.read(initialTokenProvider),
);

/// 부가 상태들
final authUserProvider  = StateProvider<Map<String, dynamic>?>((ref) => null);
final authErrorProvider = StateProvider<String?>((ref) => null);
final authLastEventProvider = StateProvider<AuthChangeEvent?>((ref) => null);

/// 필요 시 직접 클라이언트 접근용
final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

// -----------------------------
// Record
// -----------------------------

/// RecordService 주입
///
/// ✅ 핵심: jwtProvider 클로저 안에서 `ref.read(authTokenProvider)`를 매 호출 시점에 읽어서
/// 항상 최신 토큰을 Authorization 헤더에 넣는다.
/// (초기 렌더 시 토큰이 비어 있어도, 토큰이 생긴 뒤 호출하면 최신 값 사용)
final recordServiceProvider = Provider<RecordService>((ref) {
  return RecordService(
    jwtProvider: () {
      final t = ref.read(authTokenProvider);
      return (t == null || t.isEmpty) ? '' : 'Bearer $t';
    },
  );
});

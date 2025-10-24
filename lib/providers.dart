//providers.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
// ↓↓↓ 2번 적용: 모바일/데스크탑에서 keep-alive + gzip/deflate를 잘 쓰도록 IOClient 사용
import 'dart:io' show HttpClient;
import 'package:http/io_client.dart';

import 'features/auth/service/auth_service.dart';
import 'features/auth/service/token_storage.dart';
import 'features/auth/service/auth_http_client.dart';
import 'features/record/service/record_service.dart';
import 'features/home/widget/study_time/study_time_service.dart';
import 'features/home/widget/study_count/study_count_service.dart';
import 'features/home/widget/my_ranking/my_ranking_service.dart';
import 'features/home/widget/study_record/home_record_service.dart';
import 'features/my_page/space_count/space_count_controller.dart';
import 'features/my_page/space_count/space_count_service.dart';
import 'package:moods/features/my_page/user_profile/user_profile_service.dart';
import 'package:moods/features/calendar/calendar_controller.dart';
import 'package:moods/features/calendar/calendar_service.dart';
import 'package:moods/features/calendar/dropdown/calendar_header.dart';
import 'features/home/widget/prefer_keyword/prefer_keyword_service.dart';
import 'features/home/widget/prefer_keyword/prefer_keyword_controller.dart';
// ===================== Account (탈퇴) =====================
import 'features/my_page/setting/account_delete/account_delete_service.dart';

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
// Auth 기본 프로바이더
// -----------------------------

/// Supabase 클라이언트
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// 앱 시작 시점의 초기 토큰 (있으면)
final initialTokenProvider = Provider<String?>((ref) {
  try {
    final t = Supabase.instance.client.auth.currentSession?.accessToken;
    return _pickValid(t);
  } catch (_) {
    return null;
  }
});

/// 현재 액세스 토큰(옵셔널). (다른 화면에서 참고용으로만 사용)
final authTokenProvider = StateProvider<String?>(
  (ref) => ref.read(initialTokenProvider),
);

final authUserProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
final authErrorProvider = StateProvider<String?>((ref) => null);
final authLastEventProvider = StateProvider<AuthChangeEvent?>((ref) => null);

// -----------------------------
// SecureStorage / TokenStorage
// -----------------------------

// SecureStorage
final flutterSecureStorageProvider = Provider(
  (ref) => const FlutterSecureStorage(),
);

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final fs = ref.read(flutterSecureStorageProvider);
  return TokenStorage(storage: fs);
});

// ========== 2번 적용 포인트 ==========
// 기본 http.Client 대신 IOClient를 써서
// - keep-alive(연결 재사용)
// - maxConnectionsPerHost(동시 연결 수 상승)
// - autoUncompress(gzip/deflate 자동 해제)
// 를 활성화. 웹(kIsWeb)에서는 기존 Client 사용.
final baseHttpClientProvider = Provider<http.Client>((ref) {
  if (kIsWeb) {
    return http.Client();
  }
  final io = HttpClient()
    ..autoUncompress = true
    ..maxConnectionsPerHost = 8
    ..idleTimeout = const Duration(seconds: 15);
  return IOClient(io);
});

// AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.read(baseHttpClientProvider),
    ref.read(tokenStorageProvider),
  );
});

// AuthHttpClient (인터셉터)
final authHttpClientProvider = Provider<http.Client>((ref) {
  return AuthHttpClient(
    base: ref.read(baseHttpClientProvider),
    storage: ref.read(tokenStorageProvider),
    auth: ref.read(authServiceProvider),
  );
});

// RecordService
final recordServiceProvider = Provider<RecordService>((ref) {
  final client = ref.read(authHttpClientProvider);
  return RecordService(client: client);
});

/// StudyTimeService (방식: 토큰을 붙여주는 http.Client 주입)
final studyTimeServiceProvider = Provider<StudyTimeService>((ref) {
  final client = ref.read(authHttpClientProvider); // 이미 토큰을 자동으로 붙여줌
  return StudyTimeService(
    jwtProvider: () => '', // 여기서는 쓰지 않게 비워둔다 (AuthHttpClient가 처리)
    client: client,
  );
});

final studyCountServiceProvider = Provider<StudyCountService>((ref) {
  final client = ref.read(authHttpClientProvider); // 이미 Authorization 자동 주입
  return StudyCountService(
    jwtProvider: () => '', // 여기에서는 사용하지 않음 (인터셉터가 처리)
    client: client,
  );
});

// MyRankingService (AuthHttpClient 사용: 토큰 자동 부착)
final myRankingServiceProvider = Provider<MyRankingService>((ref) {
  final client = ref.read(authHttpClientProvider);
  return MyRankingService(client: client);
});

final homeRecordServiceProvider = Provider<HomeRecordService>((ref) {
  final client = ref.read(authHttpClientProvider); // Authorization 자동 주입
  return HomeRecordService(
    jwtProvider: () => '', // 여기선 사용 안 함 (인터셉터가 처리)
    client: client,
  );
});

/// StudySpaceCountService (B 방식: AuthHttpClient 사용)
final studySpaceCountServiceProvider = Provider<StudySpaceCountService>((ref) {
  final client = ref.read(authHttpClientProvider); // Authorization 자동 부착
  return StudySpaceCountService(
    jwtProvider: () => '', // 여기선 사용 안 함
    client: client,
  );
});

/// StudySpaceCountController
final studySpaceCountControllerProvider =
    StateNotifierProvider<StudySpaceCountController, StudySpaceCountState>((
      ref,
    ) {
      final svc = ref.read(studySpaceCountServiceProvider);
      return StudySpaceCountController(service: svc);
    });

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  final client = ref.read(authHttpClientProvider); // Authorization 자동 부착
  return UserProfileService(
    jwtProvider: () => '', // 여기선 사용 안 함
    client: client,
  );
});

// Service (B 방식: AuthHttpClient 사용)
final accountServiceProvider = Provider<AccountService>((ref) {
  final client = ref.read(authHttpClientProvider); // Authorization 자동 부착
  return AccountService(
    jwtProvider: () => '', // 여기선 사용 안 함 (AuthHttpClient가 처리)
    client: client,
  );
});

// Calendar Service Provider
final calendarServiceProvider = Provider<CalendarService>((ref) {
  // ✅ 토큰 자동 부착되는 AuthHttpClient 사용
  final client = ref.read(authHttpClientProvider);
  return CalendarService(client: client); // getJwt 안 넘겨도 됨
});

// Calendar Controller Provider
final calendarControllerProvider =
    StateNotifierProvider<CalendarController, CalendarState>((ref) {
      final svc = ref.read(calendarServiceProvider);
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      return CalendarController(ref, svc, initialMonth: firstDay);
    });

// 현재 선택된 연/월
final selectedYearMonthProvider = StateProvider<YearMonth>(
  (ref) => YearMonth.now(),
);

// PreferKeywordService (AuthHttpClient 사용: 토큰 자동 부착)
final preferKeywordServiceProvider = Provider<PreferKeywordService>((ref) {
  final client = ref.read(authHttpClientProvider);
  return PreferKeywordService(client: client);
});

// PreferKeywordController
final preferKeywordControllerProvider =
    StateNotifierProvider<PreferKeywordController, PreferKeywordState>((ref) {
      final svc = ref.read(preferKeywordServiceProvider);
      return PreferKeywordController(service: svc);
    });

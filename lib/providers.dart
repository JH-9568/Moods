import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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
// http client
final baseHttpClientProvider = Provider<http.Client>((ref) => http.Client());

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

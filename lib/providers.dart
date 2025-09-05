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
final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

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

final authUserProvider      = StateProvider<Map<String, dynamic>?>((ref) => null);
final authErrorProvider     = StateProvider<String?>((ref) => null);
final authLastEventProvider = StateProvider<AuthChangeEvent?>((ref) => null);

// -----------------------------
// SecureStorage / TokenStorage
// -----------------------------

// SecureStorage
final flutterSecureStorageProvider =
    Provider((ref) => const FlutterSecureStorage());

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
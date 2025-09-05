// lib/features/auth/service/auth_http_client.dart
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'token_storage.dart';
import 'auth_service.dart';

class AuthHttpClient extends http.BaseClient {
  final http.Client base;
  final TokenStorage storage;
  final AuthService auth;

  AuthHttpClient({
    required this.base,
    required this.storage,
    required this.auth,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1) Authorization 주입: TokenStorage → 없으면 Supabase JWT fallback
    await _injectAuthHeaderIfAny(request);

    // 2) 전송
    final first = await base.send(request);
    if (first.statusCode != 401) return first;

    // 3) 401 → 저장된 이메일/비번으로 재로그인해서 access 재발급 후 재시도
    final reloginOk = await auth.reloginWithSavedCredentials();
    if (reloginOk) {
      final retry = _cloneForRetry(request);
      await _injectAuthHeaderIfAny(retry);
      final second = await base.send(retry);
      if (second.statusCode != 401) return second;
    }

    // 4) (카카오/Supabase 경로) 세션이 있다면 refreshSession 시도 후 재시도
    try {
      final supa = Supabase.instance.client;
      if (supa.auth.currentSession != null) {
        await supa.auth.refreshSession();
        final retry2 = _cloneForRetry(request);
        await _injectAuthHeaderIfAny(retry2);
        final third = await base.send(retry2);
        return third;
      }
    } catch (_) {}

    return first;
  }

  Future<void> _injectAuthHeaderIfAny(http.BaseRequest req) async {
    // ① 내 백엔드 액세스 토큰 → ② Supabase 세션 토큰 순으로 시도
    String? token = await storage.readAccessToken();
    token ??= Supabase.instance.client.auth.currentSession?.accessToken;

    if (token != null && token.isNotEmpty) {
      var header = token.trim();
      // 🔒 무조건 Bearer 접두사 보장(대소문자 무시)
      if (!header.toLowerCase().startsWith('bearer ')) {
        header = 'Bearer $header';
      }
      req.headers['Authorization'] = header;

      // 디버깅(마스킹)
      final show = header.length <= 16 ? header : '${header.substring(0, 16)}•••';
      // ignore: avoid_print
      print('AuthHttpClient: inject Authorization -> $show  (${req.method} ${req.url})');
    } else {
      req.headers.remove('Authorization');
      // ignore: avoid_print
      print('AuthHttpClient: no token to inject  (${req.method} ${req.url})');
    }
  }

  http.Request _cloneForRetry(http.BaseRequest req) {
    final copy = http.Request(req.method, req.url);
    copy.headers.addAll(req.headers);
    copy.followRedirects = req.followRedirects;
    copy.maxRedirects = req.maxRedirects;
    copy.persistentConnection = req.persistentConnection;
    if (req is http.Request) {
      copy.bodyBytes = req.bodyBytes;
    }
    return copy;
  }
}

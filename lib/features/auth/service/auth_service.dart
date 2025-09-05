// lib/features/auth/service/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao; // (사용 중이면 유지)
import 'package:moods/common/constants/api_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode;

import 'token_storage.dart';

class AuthService {
  AuthService(this.httpClient, this.storage);

  final http.Client httpClient;
  final TokenStorage storage;

  final _supabase = Supabase.instance.client;
  static const _defaultTimeout = Duration(seconds: 12);

  Uri _u(String path, [Map<String, String>? q]) {
    final uri = Uri.parse('$baseUrl$path');
    return (q == null) ? uri : uri.replace(queryParameters: q);
  }

  // ───────────────── 이메일 인증 확인 ─────────────────
  Future<bool> checkEmailVerified(String uuid) async {
    final url = _u('/auth/is-verified', {'id': uuid});
    final jwt = _supabase.auth.currentSession?.accessToken;

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
    };

    try {
      final res = await httpClient.get(url, headers: headers).timeout(_defaultTimeout);
      if (res.statusCode == 401 || res.statusCode == 403) return false;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map) {
          if (data['confirmed_at'] != null) return true;
          if (data['confirmedAt'] != null)  return true;
          if (data['verified'] == true)      return true;
          if (data['isVerified'] == true)    return true;
        }
        return false;
      }
      throw Exception('이메일 인증 확인 실패: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('이메일 인증 확인 HTTP 실패: $e');
      return false;
    }
  }

  // ─────────────── 카카오(Supabase OAuth) ───────────────
  Future<void> loginWithKakao() async {
    await _supabase.auth.signOut();
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.kakao,
      redirectTo: 'moods://login-callback',
      scopes: 'account_email profile_nickname profile_image',
      authScreenLaunchMode: LaunchMode.externalApplication,
      queryParams: {'prompt': 'login'},
    );
  }

  Future<void> syncEmailIntoUsers() async {
    final auth = _supabase.auth;
    final u0 = auth.currentUser;
    if (u0 == null) return;

    String? email = u0.email;
    if (email == null || email.isEmpty) {
      final res = await auth.getUser();
      final u = res.user;
      email = u?.email;
      if ((email == null || email.isEmpty) && (u?.identities != null)) {
        for (final id in u!.identities!) {
          final e = id.identityData?['email'] as String?;
          if (e != null && e.isNotEmpty) { email = e; break; }
        }
      }
      email ??= (u?.userMetadata?['email'] as String?);
    }

    if (email != null && email.isNotEmpty) {
      await _supabase.from('users').update({'email': email}).eq('id', u0.id);
    }
  }

  Map<String, dynamic>? getCurrentSessionInfo() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return {'id': user.id, 'email': user.email, 'metadata': user.userMetadata};
  }

  // ───────────────────── 로그아웃 ─────────────────────
  Future<void> signOut() async {
    // 서버에 /auth/logout 이 필요한 설계가 아니라면 여기선 로컬 정리만
    await storage.clearAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');

    try { await _supabase.auth.signOut(); } catch (_) {}
  }

  Future<void> ensureUserRow() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final existing = await _supabase.from('users').select('id').eq('id', uid).maybeSingle();
    if (existing == null) {
      await _supabase.from('users').insert({'id': uid});
    }
  }

  // ─────────────── 초기 인증/회원가입 ───────────────
  Future<String?> sendInitialVerificationEmail(String email) async {
    final res = await httpClient
        .post(
          _u('/auth/send-verification'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('초기 인증메일 전송 실패: ${res.statusCode} ${res.body}');
    }
    if (res.body.isEmpty) return null;

    final data = jsonDecode(res.body);
    if (data is Map) {
      final user = data['user'];
      if (user is Map && user['id'] is String) return user['id'] as String;
      if (data['id'] is String) return data['id'] as String;
    }
    return null;
  }

  Future<String?> requestInitialVerification({
    required String email,
    required String password,
    required String nickname,
    required String birth,
    required String gender,
  }) async {
    final res = await httpClient
        .post(
          _u('/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'nickname': nickname,
            'birthday': birth,
            'gender': gender,
          }),
        )
        .timeout(_defaultTimeout);

    debugPrint('[signup] ${res.statusCode} ${res.body}');
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      if (data is Map &&
          data['user'] is Map &&
          (data['user'] as Map).containsKey('id')) {
        return (data['user'] as Map)['id'] as String;
      }
      throw Exception('서버 응답에 사용자 ID(UUID)가 없습니다.');
    }
    throw Exception('인증 요청 실패: ${res.statusCode} ${res.body}');
  }

  Future<void> completeEmailSignUp({
    required String userId,    // uuid
    required String email,
    required String password,
    required String nickname,
    required String birth,     // YYYY-MM-DD
    required String gender,    // 'm' | 'f'
  }) async {
    final res = await httpClient
        .post(
          _u('/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'password': password,
            'nickname': nickname,
            'birthday': birth,
            'gender': gender,
            'email': email,
          }),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('회원가입 실패: ${res.statusCode} ${res.body}');
    }
  }

  // ─────────────── 로그인 / 토큰 저장 ───────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await httpClient
        .post(
          _u('/auth/signin'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_defaultTimeout);

    debugPrint('[signin] ${res.statusCode} ${res.body}');
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('로그인 실패: ${res.statusCode} ${res.body}');
    }

    final parsed = jsonDecode(res.body);
    Map<String, dynamic> session = {};

    if (parsed is Map && parsed['session'] is Map) {
      session = (parsed['session'] as Map).cast<String, dynamic>();
    } else if (parsed is Map) {
      // 레거시 포맷 방어
      final token = (parsed['access_token'] ??
          parsed['accessToken'] ??
          parsed['token'] ??
          parsed['jwt']);
      if (token is String && token.isNotEmpty) {
        session = {
          'access_token': token,
        };
        if (parsed['refresh_token'] is String) {
          session['refresh_token'] = parsed['refresh_token'];
        }
      }
    }

    final acc = (session['access_token'] ?? session['accessToken'])?.toString();
    if (acc == null || acc.isEmpty) {
      throw Exception('로그인 응답에 access_token이 없습니다.');
    }

    // (레거시) SharedPreferences에도 저장해두는 중
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', acc);

    // 보안 저장
    await storage.saveAccessToken(acc);
    if (session['refresh_token'] is String) {
      await storage.saveRefreshToken(session['refresh_token'] as String);
    }

    // 자동로그인용 자격 저장
    await storage.saveLoginPayload({'email': email, 'password': password});

    return session;
  }

  // ─────────── 인증코드/비번재설정 ───────────
  Future<void> sendVerificationCode(String email) async {
    final res = await httpClient
        .get(
          _u('/auth/resend-signup-verification', {'email': email}),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(_defaultTimeout);
    if (res.statusCode != 200) {
      throw Exception('인증번호 전송 실패: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final res = await httpClient
        .get(
          _u('/auth/reset-password', {'email': email}),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(_defaultTimeout);
    if (res.statusCode != 200) {
      throw Exception('비밀번호 재설정 이메일 전송 실패: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String code,
  }) async {
    final res = await httpClient
        .post(
          _u('/auth/reset-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': newPassword, 'code': code}),
        )
        .timeout(_defaultTimeout);
    if (res.statusCode != 200) {
      throw Exception('비밀번호 재설정 실패: ${res.statusCode} ${res.body}');
    }
  }

  // ─────────────── 유저 정보 수정 ───────────────
  Future<void> patchUserInfo({
    required String nickname,
    required String genderLetter,
    required String birthday,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('세션 없음 (Supabase JWT null)');
    }

    final res = await httpClient
        .patch(
          _u('/user'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'nickname': nickname,
            'gender': genderLetter,
            'birthday': birthday,
          }),
        )
        .timeout(_defaultTimeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PATCH /user 실패: ${res.statusCode} ${res.body}');
    }
  }

  Future<bool> checkPasswordChanged(Uri redirectUri) async {
    return redirectUri.path.contains('password') &&
        redirectUri.queryParameters['error_code'] == null;
  }

  // ─────────────── “자동 재로그인” (리프레시 없음) ───────────────
  /// 저장된 자격(email/password 등)으로 재로그인 시도.
  /// 성공 시 새 access 토큰이 TokenStorage에 저장됨 → true 반환
  /// 저장 데이터 없거나 실패 시 false
  Future<bool> reloginWithSavedCredentials() async {
    final payload = await storage.readLoginPayload();
    final email = payload is Map ? payload['email'] as String? : null;
    final pw    = payload is Map ? payload['password'] as String? : null;

    if (email == null || pw == null || email.isEmpty || pw.isEmpty) {
      return false;
    }

    try {
      final session = await login(email, pw);
      return (session['access_token'] != null);
    } catch (_) {
      return false;
    }
  }

  /// ⬅️ `AuthHttpClient`에서 호출할 별칭(이름만 다른 동일 동작)
  Future<bool> reissueAccessOnly() => reloginWithSavedCredentials();
}

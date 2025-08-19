// auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:moods/common/constants/api_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode;

class AuthService {
  final _supabase = Supabase.instance.client;

  Uri _u(String path, [Map<String, String>? q]) {
    final uri = Uri.parse('$baseUrl$path');
    return (q == null) ? uri : uri.replace(queryParameters: q);
  }

  static const _defaultTimeout = Duration(seconds: 12);

  Future<bool> checkEmailVerified(String uuid) async {
  final url = Uri.parse('$baseUrl/auth/is-verified?id=$uuid');

  // 있으면 쓰고, 없으면 빼자. (카카오로 이미 로그인돼 있으면 Supabase 세션 JWT가 있을 수 있음)
  final jwt = _supabase.auth.currentSession?.accessToken;

  final headers = <String, String>{
    'Content-Type': 'application/json',
    if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
  };

  try {
    final res = await http.get(url, headers: headers).timeout(_defaultTimeout);

    // 인증 필요한데 토큰 없어서 401/403이면 true/false 판단 불가 — 그냥 미인증으로 간주하고 폴링 계속
    if (res.statusCode == 401 || res.statusCode == 403) {
      print('is-verified 401/403 (jwt 필요). 헤더 없이 재시도는 안 함, 다음 틱에 다시 확인.');
      return false;
    }

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
    print('이메일 인증 확인 HTTP 요청 실패: $e');
    // 네트워크 에러 등은 폴링 계속하기 위해 false
    return false;
  }
}


// AuthService.loginWithKakao
Future<void> loginWithKakao() async {
  await _supabase.auth.signOut(); // 깔끔하게

  await _supabase.auth.signInWithOAuth(
    OAuthProvider.kakao,
    redirectTo: 'moods://login-callback',
    // 카카오 이메일 동의 받아오기
    scopes: 'account_email profile_nickname profile_image',
    // 하얀 화면 방지: 외부 브라우저/앱으로
    authScreenLaunchMode: LaunchMode.externalApplication,
    // 가능하면 재동의 강제(이전 동의가 없거나 거절됐던 케이스)
    queryParams: {'prompt': 'login'}, // 사용 중인 supabase_flutter 버전에서 지원되면 그대로 사용
  );
}

// auth_service.dart

Future<void> syncEmailIntoUsers() async {
  final auth = _supabase.auth;
  final u0 = auth.currentUser;
  if (u0 == null) return;

  String? email = u0.email;

  // 2) 최신 유저 풀오브젝트
  if (email == null || email.isEmpty) {
    final res = await auth.getUser();
    final u = res.user;
    email = u?.email;

    // 3) identities에 있을 수도 있음
    if ((email == null || email.isEmpty) && (u?.identities != null)) {
      for (final id in u!.identities!) {
        final e = id.identityData?['email'] as String?;
        if (e != null && e.isNotEmpty) {
          email = e;
          break;
        }
      }
    }

    // 4) user_metadata에 있을 수도 있음
    email ??= (u?.userMetadata?['email'] as String?);
  }

  if (email != null && email.isNotEmpty) {
    // 내 row만 업데이트 가능하도록 RLS 정책이 있어야 함(아래 참고)
    await _supabase
        .from('users')
        .update({'email': email})
        .eq('id', u0.id);
  }
}






  Map<String, dynamic>? getCurrentSessionInfo() {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return {
      'id': user.id,
      'email': user.email,
      'metadata': user.userMetadata,
    };
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await _supabase.auth.signOut();
  }

  Future<void> ensureUserRow() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final existing = await _supabase
        .from('users')
        .select('id')
        .eq('id', uid)
        .maybeSingle();
    if (existing == null) {
      await _supabase.from('users').insert({'id': uid});
    }
  }
 
  // 이메일만 보내서 최초 인증 메일 전송
  Future<String?> sendInitialVerificationEmail(String email) async {
  try {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/send-verification'),
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
      // user.id 우선 체크
      final user = data['user'];
      if (user is Map && user['id'] is String) {
        return user['id'] as String;
      }
      // 최상위 id 체크
      if (data['id'] is String) {
        return data['id'] as String;
      }
    }

    return null; // UUID 못 찾으면 null
  } catch (e) {
    print('HTTP 요청 실패: $e');
    rethrow;
  }
}


  Future<String?> requestInitialVerification({
    required String email,
    required String password,
    required String nickname,
    required String birth,
    required String gender,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');

    try {
      final response = await http
          .post(
            url,
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

      print('서버 응답 상태 코드: ${response.statusCode}');
      print('서버 응답 본문: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data.containsKey('user') &&
            data['user'] is Map &&
            (data['user'] as Map).containsKey('id')) {
          return data['user']['id'] as String;
        } else {
          throw Exception('서버 응답에 사용자 ID(UUID)가 포함되어 있지 않습니다.');
        }
      } else {
        throw Exception('인증 요청 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('HTTP 요청 실패: $e');
      rethrow;
    }
  }

  Future<void> completeEmailSignUp({
  required String userId,    // ★ uuid
  required String email,
  required String password,
  required String nickname,
  required String birth,     // YYYY-MM-DD
  required String gender,    // 'm' | 'f' (백엔드 스펙에 맞춰)
}) async {
  try {
    final res = await http
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
  } catch (e) {
    print('회원가입 HTTP 실패: $e');
    rethrow;
  }
}


  Future<Map<String, dynamic>> login(String email, String password) async {
  final url = Uri.parse('$baseUrl/auth/signin');

  try {
    final res = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_defaultTimeout);

    // 디버그 확인용
    // ignore: avoid_print
    print('[signin] ${res.statusCode} ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);

      if (data is Map && data['session'] is Map) {
        // 서버 예시 포맷 그대로 반환
        return (data['session'] as Map).cast<String, dynamic>();
      }

      // 혹시 레거시 형태(top-level)라도 방어
      if (data is Map) {
        final token = (data['access_token'] ?? data['accessToken'] ?? data['token'] ?? data['jwt']);
        final user  = (data['user'] is Map) ? (data['user'] as Map).cast<String, dynamic>() : null;
        if (token is String && token.isNotEmpty) {
          return {
            'access_token': token,
            if (user != null) 'user': user,
          };
        }
      }

      throw Exception('로그인 응답에서 session/토큰을 찾지 못했습니다.');
    }

    throw Exception('로그인 실패: ${res.statusCode} ${res.body}');
  } catch (e) {
    // ignore: avoid_print
    print('HTTP 로그인 실패: $e');
    rethrow;
  }
}

  Future<void> sendVerificationCode(String email) async {
    final url = Uri.parse('$baseUrl/auth/resend-signup-verification?email=$email');

    try {
      final response = await http
          .get(
            url,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_defaultTimeout);

      if (response.statusCode != 200) {
        throw Exception('인증번호 전송 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('HTTP 요청 실패: $e');
      rethrow;
    }
  }


  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final res = await http
          .get(
            _u('/auth/reset-password', {'email': email}),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_defaultTimeout);

      if (res.statusCode != 200) {
        throw Exception('비밀번호 재설정 이메일 전송 실패: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('HTTP 요청 실패: $e');
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String code,
  }) async {
    try {
      final res = await http
          .post(
            _u('/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'email': email, 'password': newPassword, 'code': code}),
          )
          .timeout(_defaultTimeout);

      if (res.statusCode != 200) {
        throw Exception('비밀번호 재설정 실패: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('HTTP 요청 실패: $e');
      rethrow;
    }
  }

  Future<void> patchUserInfo({
    required String nickname,
    required String genderLetter,
    required String birthday,
  }) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      if (token == null) throw Exception('세션 없음 (JWT null)');

      final res = await http
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
    } catch (e) {
      print('HTTP 요청 실패: $e');
      rethrow;
    }
  }

  Future<bool> checkPasswordChanged(Uri redirectUri) async {
    return redirectUri.path.contains('password') &&
        redirectUri.queryParameters['error_code'] == null;
  }
  
}

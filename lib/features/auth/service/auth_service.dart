// auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

class AuthService {
  /// 최초 인증번호 요청 (회원가입 요청처럼 보냄) → UUID 반환
  Future<String?> requestInitialVerification({
    required String email,
    required String password,
    required String nickname,
    required String birth,
    required String gender,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'nickname': nickname,
          'birthday': birth,
          'gender': gender,
        }),
      );
      
      print('서버 응답 상태 코드: ${response.statusCode}');
      print('서버 응답 본문: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data.containsKey('user') && data['user'] is Map && data['user'].containsKey('id')) {
          return data['user']['id']; 
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

  /// 최종 회원가입 확정
  Future<void> confirmSignUp({
    required String email,
    required String password,
    required String nickname,
    required String birth,
    required String gender,
  }) async {
    final url = Uri.parse('$baseUrl/auth/confirm-signup');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'nickname': nickname,
        'birthday': birth,
        'gender': gender,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('회원가입 확정 실패: ${response.statusCode} ${response.body}');
    }
  }

  /// 로그인
  Future<String> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/signin');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      throw Exception('로그인 실패: ${response.statusCode} ${response.body}');
    }
  }

  /// 이메일 인증번호 재전송
  Future<void> sendVerificationCode(String email) async {
    final url = Uri.parse('$baseUrl/auth/resend-signup-verification?email=$email');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('인증번호 전송 실패: ${response.statusCode} ${response.body}');
    }
  }

  /// 이메일 인증 여부 확인 (UUID 기반으로 수정됨)
  Future<bool> checkEmailVerified(String uuid) async {
    final url = Uri.parse('$baseUrl/auth/is-verified?id=$uuid');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('인증 확인 응답 상태 코드: ${response.statusCode}');
      print('인증 확인 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ✅ 서버 응답에 맞춰 'confirmed_at' 키가 null이 아닌지 확인하도록 수정
        return data.containsKey('confirmed_at') && data['confirmed_at'] != null;
      } else {
        throw Exception('이메일 인증 확인 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('이메일 인증 확인 HTTP 요청 실패: $e');
      rethrow;
    }
  }
}
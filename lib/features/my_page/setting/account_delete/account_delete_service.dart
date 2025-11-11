// lib/features/my_page/setting/account_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

typedef JwtProvider = String Function();

/// 계정 관련(탈퇴 등) API
class AccountService {
  final JwtProvider jwtProvider;
  final http.Client _client;
  AccountService({required this.jwtProvider, http.Client? client})
    : _client = client ?? http.Client();

  Map<String, String> get _headers {
    // B 방식: authHttpClientProvider가 토큰을 자동 부착하지만,
    // 혹시를 위해 비어있지 않으면 추가하도록 유지
    final token = jwtProvider();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) h['Authorization'] = token;
    return h;
  }

  Uri _u(String p) => Uri.parse('$baseUrl$p');

  /// DELETE /user (탈퇴)
  /// Postman: 200 {"message":"유저 삭제에 성공했습니다."}
  Future<String> deleteMe() async {
    final url = _u('/user');
    final res = await _client.delete(url, headers: _headers);
    print('[AccountService] DELETE $url status=${res.statusCode}');
    print('[AccountService] body=${res.body}');

    if (res.statusCode ~/ 100 != 2) {
      throw Exception('유저 삭제 실패: ${res.statusCode} ${res.body}');
    }

    try {
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return (map['message'] ?? '').toString();
    } catch (_) {
      return res.body;
    }
  }
}

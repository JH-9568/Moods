import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

typedef JwtProvider = String Function();

class UserProfile {
  final String id;
  final String nickname;
  final String? profileImageUrl;
  final String? birthday; // "YYYY-MM-DD"
  final String email;
  final String? gender; // "m" | "f" | null

  const UserProfile({
    required this.id,
    required this.nickname,
    required this.email,
    this.profileImageUrl,
    this.birthday,
    this.gender,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    return UserProfile(
      id: (j['id'] ?? '').toString(),
      nickname: (j['nickname'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      profileImageUrl: j['profile_img_url']?.toString(),
      birthday: j['birthday']?.toString(),
      gender: j['gender']?.toString(),
    );
  }
}

class UserProfileService {
  final JwtProvider jwtProvider;
  final http.Client _client;
  UserProfileService({required this.jwtProvider, http.Client? client})
    : _client = client ?? http.Client();

  Map<String, String> get _headers {
    // B 방식: AuthHttpClient가 Authorization을 붙여주므로 여기서는 옵션
    final token = jwtProvider();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) h['Authorization'] = token;
    return h;
  }

  Uri _u(String p) => Uri.parse('$baseUrl$p');

  /// GET /user
  /// Postman 예시: user 객체에 id, nickname, birthday, email, gender 포함
  Future<UserProfile> fetchUserProfile() async {
    final url = _u('/user');
    final res = await _client.get(url, headers: _headers);
    print('[UserProfileService] GET $url status=${res.statusCode}');
    print('[UserProfileService] body=${res.body}');

    if (res.statusCode ~/ 100 != 2) {
      throw Exception('유저 정보 조회 실패: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> map =
        jsonDecode(res.body) as Map<String, dynamic>;
    final Map<String, dynamic> u =
        (map['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    return UserProfile.fromJson(u);
  }
}

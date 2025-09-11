// lib/features/home/widget/my_page/study_space_count_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

/// 외부에서 최신 JWT를 주입받기 위한 타입(B 방식에서는 사실상 사용 안함)
typedef JwtProvider = String Function();

class StudySpaceCountService {
  final JwtProvider jwtProvider;
  final http.Client _client;

  StudySpaceCountService({required this.jwtProvider, http.Client? client})
    : _client = client ?? http.Client();

  Map<String, String> get _headers {
    // B 방식: AuthHttpClient가 Authorization을 자동 부착하므로 여긴 옵션
    final token = jwtProvider();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) h['Authorization'] = token;
    return h;
  }

  Uri _u(String p) => Uri.parse('$baseUrl$p');

  /// GET /stats/my-summary/space-count
  /// 응답 예시:
  /// { "success": true, "total_spaces": 2 }
  Future<int> fetchTotalSpaces() async {
    final uri = _u('/stats/my-summary/space-count');
    final res = await _client.get(uri, headers: _headers);

    print('[StudySpaceCountService] GET $uri status=${res.statusCode}');
    print('[StudySpaceCountService] body=${res.body}');

    if (res.statusCode ~/ 100 != 2) {
      throw Exception('공부 장소 개수 조회 실패: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final v = map['total_spaces'];
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

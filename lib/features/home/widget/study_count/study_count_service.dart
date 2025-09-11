// lib/features/home/widget/study_count/study_count_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

typedef JwtProvider = String Function();

class StudyCountService {
  final JwtProvider jwtProvider;
  final http.Client _client;
  StudyCountService({required this.jwtProvider, http.Client? client})
    : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final token = jwtProvider();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) h['Authorization'] = token;
    return h;
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  /// GET /stats/my-summary/total → { success, total_sessions }
  Future<int> fetchTotalSessions() async {
    final uri = _u('/stats/my-summary/total');
    final res = await _client.get(uri, headers: _headers);

    // 로그
    // ignore: avoid_print
    print('[StudyCountService] GET $uri status=${res.statusCode}');
    // ignore: avoid_print
    print('[StudyCountService] body=${res.body}');

    if (res.statusCode ~/ 100 != 2) {
      throw Exception('총 공부횟수 호출 실패: ${res.statusCode} ${res.body}');
    }
    final Map<String, dynamic> data =
        jsonDecode(res.body) as Map<String, dynamic>;
    final n = data['total_sessions'];
    if (n is int) return n;
    if (n is num) return n.toInt();
    return int.tryParse('$n') ?? 0;
  }
}

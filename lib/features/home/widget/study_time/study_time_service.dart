import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart'; // baseUrl

/// 외부에서 최신 JWT를 주입받기 위한 타입
/// 예) () => 'Bearer xxx' 또는 ''(미로그인 시)
typedef JwtProvider = String Function();

class StudyTimeService {
  final JwtProvider jwtProvider;
  final http.Client _client;

  StudyTimeService({required this.jwtProvider, http.Client? client})
    : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final token = jwtProvider();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) headers['Authorization'] = token;
    return headers;
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  /// GET /stats/my-summary/monthly
  /// 응답 예시: items: [{ month: "YYYY-MM", total_minutes: 123 }, ...]
  /// → 현재 로컬 시각 기준 YYYY-MM 과 일치하는 항목의 total_minutes 반환 (없으면 0)
  Future<int> fetchThisMonthTotalMinutes() async {
    final res = await _client.get(
      _u('/stats/my-summary/monthly'),
      headers: _headers,
    );

    if (res.statusCode ~/ 100 != 2) {
      throw Exception('월별 통계 호출 실패: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> data =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List items = (data['items'] ?? []) as List;

    final now = DateTime.now();
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}'; // e.g. 2025-08

    final match = items.cast<Map<String, dynamic>>().firstWhere(
      (e) => (e['month'] as String?) == monthKey,
      orElse: () => const {},
    );

    return (match['total_minutes'] ?? 0) as int;
  }

  /// GET /stats/my-summary/weekly
  /// 응답 예시: items: [{ week_start: "YYYY-MM-DD", total_minutes: 123 }, ...]
  /// → "이번 주(일요일 시작)"의 week_start 를 계산해 total_minutes 반환 (없으면 0)
  Future<int> fetchThisWeekTotalMinutes() async {
    final res = await _client.get(
      _u('/stats/my-summary/weekly'),
      headers: _headers,
    );

    if (res.statusCode ~/ 100 != 2) {
      throw Exception('주별 통계 호출 실패: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> data =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List items = (data['items'] ?? []) as List;

    // Dart: Monday=1 ... Sunday=7 → 일요일 시작으로 환산
    final now = DateTime.now();
    final int daysFromSunday = now.weekday % 7; // Sunday=0
    final sunday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysFromSunday));

    final weekKey =
        '${sunday.year.toString().padLeft(4, '0')}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';

    final match = items.cast<Map<String, dynamic>>().firstWhere(
      (e) => (e['week_start'] as String?) == weekKey,
      orElse: () => const {},
    );

    return (match['total_minutes'] ?? 0) as int;
  }
}

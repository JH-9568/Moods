// lib/features/home/widget/study_time/study_time_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

typedef JwtProvider = String Function();

class StudyTimeService {
  final JwtProvider jwtProvider;
  final http.Client _client;
  StudyTimeService({required this.jwtProvider, http.Client? client})
    : _client = client ?? http.Client();

  Map<String, String> get _headers {
    // B 방식: AuthHttpClient가 토큰을 붙여주므로 여기서는 옵션
    final token = jwtProvider();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) h['Authorization'] = token;
    return h;
  }

  Uri _u(String p) => Uri.parse('$baseUrl$p');

  // "HH:MM:SS" -> Duration
  Duration _parseTimeDisplay(String? s) {
    if (s == null || s.isEmpty) return Duration.zero;
    final parts = s.split(':');
    if (parts.length < 2) return Duration.zero;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final sec = (parts.length >= 3) ? (int.tryParse(parts[2]) ?? 0) : 0;
    return Duration(hours: h, minutes: m, seconds: sec);
  }

  /// GET /stats/my-summary/monthly
  /// {
  /// "success": true, "year": 2025, "month": 9,
  /// "data": { "month":"2025-09", "sessions":38, "time_display":"00:54:57" }
  /// }
  Future<Duration> fetchThisMonthDuration() async {
    final res = await _client.get(
      _u('/stats/my-summary/monthly'),
      headers: _headers,
    );
    print('[StudyTimeService] monthly status=${res.statusCode}');
    print('[StudyTimeService] monthly body=${res.body}');
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('월간 통계 호출 실패: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final data =
        (map['data'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final td = data['time_display']?.toString();

    final dur = _parseTimeDisplay(td);
    print('[StudyTimeService] monthly parsed duration=${_fmt(dur)}');
    return dur;
  }

  /// GET /stats/my-summary/weekly
  /// { "success": true, "current_week": { "sessions":7, "time_display":"00:45:39" } }
  Future<Duration> fetchThisWeekDuration() async {
    final res = await _client.get(
      _u('/stats/my-summary/weekly'),
      headers: _headers,
    );
    print('[StudyTimeService] weekly status=${res.statusCode}');
    print('[StudyTimeService] weekly body=${res.body}');
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('주간 통계 호출 실패: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final cur =
        (map['current_week'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final td = cur['time_display']?.toString();

    final dur = _parseTimeDisplay(td);
    print('[StudyTimeService] weekly parsed duration=${_fmt(dur)}');
    return dur;
  }

  String _fmt(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:'
      '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

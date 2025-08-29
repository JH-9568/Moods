// lib/features/home/widget/study_time/study_time_service.dart
// 역할: 백엔드(POSTMAN) 월별/주별 통계를 호출하고, "이번 달 / 이번 주" 합계를 반환

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart'; // baseUrl 고정 사용

/// 외부에서 JWT를 주입하기 위한 타입.
/// 예: () => 'Bearer <token>';  토큰이 없으면 빈 문자열("") 반환 가능.
typedef JwtProvider = String Function();

class StudyTimeService {
  final JwtProvider jwtProvider;
  final http.Client _client;

  StudyTimeService({
    required this.jwtProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final token = jwtProvider();
    // Authorization 헤더는 값이 있을 때만 추가
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) headers['Authorization'] = token;
    return headers;
  }

  // 안전한 URL 생성: baseUrl의 scheme/host/port를 그대로 쓰고, path는 결합
  Uri _buildUri(String prefix, String tailPath) {
    final b = Uri.parse(baseUrl);
    final scheme = b.scheme.isEmpty ? 'http' : b.scheme;
    final host = b.host.isEmpty ? b.toString() : b.host;
    final port = b.hasPort ? b.port : (scheme == 'https' ? 443 : 3000);

    String _join(String a, String b) {
      final left = a.endsWith('/') ? a.substring(0, a.length - 1) : a;
      final right = b.startsWith('/') ? b : '/$b';
      if (left.isEmpty || left == '/') return right; // base path가 비어 있으면 tail만
      return '$left$right';
    }

    // baseUrl.path + prefix + tailPath 결합
    final path = _join(_join(b.path, prefix), tailPath);
    return Uri(scheme: scheme, host: host, port: port, path: path);
  }

  /// 1차: /stats/...  이후: /api, /v1, /api/v1 프리픽스 순으로 재시도
  /// baseUrl.path에 이미 동일 토큰(api, v1)이 있으면 중복 후보는 건너뜀
  Future<({http.Response res, Uri url, List<String> attempts})> _getWithFallback(String tailPath) async {
    final b = Uri.parse(baseUrl);
    final tokens = b.path.split('/').where((e) => e.isNotEmpty).toSet();

    final candidates = <String>[''];
    if (!tokens.contains('api')) candidates.add('/api');
    if (!tokens.contains('v1')) candidates.add('/v1');
    if (!(tokens.contains('api') && tokens.contains('v1'))) candidates.add('/api/v1');

    final attempts = <String>[];
    http.Response? last;
    Uri? lastUrl;

    for (final p in candidates) {
      final url = _buildUri(p, tailPath);
      final res = await _client.get(url, headers: _headers);

      final ct = res.headers['content-type'] ?? '';
      attempts.add('$url -> ${res.statusCode} ${ct.isNotEmpty ? '[' + ct + ']' : ''}');

      // 2xx 성공
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return (res: res, url: url, attempts: attempts);
      }

      // 404 혹은 HTML 에러 페이지면 다음 후보 시도
      final isHtml = ct.contains('text/html') || res.body.startsWith('<!DOCTYPE html>');
      if (res.statusCode == 404 || isHtml) {
        last = res; lastUrl = url; continue;
      }

      // 401/500 등은 즉시 반환
      return (res: res, url: url, attempts: attempts);
    }

    return (
      res: last ?? http.Response('Not Found', 404),
      url: lastUrl ?? _buildUri('', tailPath),
      attempts: attempts,
    );
  }

  /// 월별 통계 호출 → 이번 달(total_minutes) 반환
  Future<int> fetchThisMonthTotalMinutes() async {
    final r = await _getWithFallback('/stats/my-summary/monthly');
    if (r.res.statusCode ~/ 100 != 2) {
      final ct = r.res.headers['content-type'] ?? '';
      final isHtml = ct.contains('text/html') || r.res.body.startsWith('<!DOCTYPE html>');
      // 라우팅 불일치(404/HTML)는 0분으로 처리하고 화면 에러는 숨김
      if (r.res.statusCode == 404 || isHtml) {
        print('[StudyTimeService] monthly attempts:\n' + r.attempts.join('\n'));
        return 0;
      }
      throw Exception('월별 통계 호출 실패: ${r.res.statusCode} [URL=${r.url}]\n${r.res.body}');
    }

    final Map<String, dynamic> data = jsonDecode(r.res.body) as Map<String, dynamic>;
    final List items = (data['items'] ?? []) as List;

    final now = DateTime.now();
    final monthKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final match = items.cast<Map<String, dynamic>>().firstWhere(
      (e) => (e['month'] as String?) == monthKey,
      orElse: () => const {},
    );
    return (match['total_minutes'] ?? 0) as int;
  }

  /// 주별 통계 호출 → "이번 주"(일요일 시작) total_minutes 반환
  Future<int> fetchThisWeekTotalMinutes() async {
    final r = await _getWithFallback('/stats/my-summary/weekly');
    if (r.res.statusCode ~/ 100 != 2) {
      final ct = r.res.headers['content-type'] ?? '';
      final isHtml = ct.contains('text/html') || r.res.body.startsWith('<!DOCTYPE html>');
      if (r.res.statusCode == 404 || isHtml) {
        print('[StudyTimeService] weekly attempts:\n' + r.attempts.join('\n'));
        return 0;
      }
      throw Exception('주별 통계 호출 실패: ${r.res.statusCode} [URL=${r.url}]\n${r.res.body}');
    }

    final Map<String, dynamic> data = jsonDecode(r.res.body) as Map<String, dynamic>;
    final List items = (data['items'] ?? []) as List;

    final now = DateTime.now();
    final int daysFromSunday = now.weekday % 7; // 일요일 0
    final sunday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromSunday));
    final weekKey = '${sunday.year.toString().padLeft(4, '0')}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';

    final match = items.cast<Map<String, dynamic>>().firstWhere(
      (e) => (e['week_start'] as String?) == weekKey,
      orElse: () => const {},
    );
    return (match['total_minutes'] ?? 0) as int;
  }
}

/*	•	_u() : baseUrl에 path만 붙입니다(포트 포함된 상수 그대로 사용).
	•	fetchThisMonthTotalMinutes() : 월별 응답 중 현재 YYYY-MM 항목의 total_minutes 추출.
	•	fetchThisWeekTotalMinutes() : 주별 응답 중 이번 주(일요일 시작) week_start의 total_minutes 추출.
	•	Authorization 은 전달되면 사용, 없으면 생략되게 처리. */
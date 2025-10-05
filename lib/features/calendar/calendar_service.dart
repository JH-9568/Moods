import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

// ====== Isolate parser (변경 없음/간결 주석) ======
List<Map<String, dynamic>> parseCalendarMonthIsolate(
  Map<String, dynamic> args,
) {
  final String rawBody = args['rawBody'] as String;
  final int year = args['year'] as int;
  final int month = args['month'] as int;

  int toSeconds(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.round();
    if (v is String) {
      final s = v.trim();
      if (s.contains(':')) {
        final parts = s.split(':');
        int h = 0, m = 0;
        double sec = 0;
        if (parts.length == 3) {
          h = int.tryParse(parts[0]) ?? 0;
          m = int.tryParse(parts[1]) ?? 0;
          sec = double.tryParse(parts[2]) ?? 0;
        } else if (parts.length == 2) {
          m = int.tryParse(parts[0]) ?? 0;
          sec = double.tryParse(parts[1]) ?? 0;
        } else if (parts.length == 1) {
          sec = double.tryParse(parts[0]) ?? 0;
        }
        return (h * 3600 + m * 60 + sec).round();
      }
      final d = double.tryParse(s);
      if (d != null) return d.round();
    }
    return 0;
  }

  String ymd(int y, int m, int d) =>
      '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

  final body = jsonDecode(rawBody);
  final rbd = (body is Map)
      ? (body['records_by_day'] ?? body['recordsByDay'])
      : null;
  if (rbd is! Map) return const <Map<String, dynamic>>[];

  final flat = <Map<String, dynamic>>[];

  rbd.forEach((dayKey, dayVal) {
    final day = int.tryParse(dayKey.toString());
    if (day == null) return;

    List recList = const [];
    if (dayVal is List) {
      recList = dayVal;
    } else if (dayVal is Map && dayVal['records'] is List) {
      recList = dayVal['records'] as List;
    }

    for (final e in recList) {
      if (e is! Map) continue;
      final rec = Map<String, dynamic>.from(e);

      final seconds = toSeconds(
        rec['duration'] ??
            rec['net_seconds'] ??
            rec['total_seconds'] ??
            rec['total_time'] ??
            rec['net_time'],
      );

      final dateStr = (rec['date']?.toString().isNotEmpty ?? false)
          ? rec['date'].toString()
          : ymd(year, month, day);

      final spaceName =
          rec['space_name']?.toString() ??
          (rec['space'] is Map ? (rec['space']['name']?.toString() ?? '') : '');

      final imageUrl = rec['image_url'] ?? rec['space_image_url'];

      flat.add({
        'id': rec['id']?.toString() ?? rec['record_id']?.toString() ?? '',
        'date': dateStr,
        'title': rec['title']?.toString() ?? '공부 기록',
        'duration': seconds,
        'space': {'name': spaceName},
        'image_url': imageUrl,
        '_origin': rec,
      });
    }
  });

  return flat;
}

class CalendarService {
  final http.Client client;

  CalendarService({required this.client});

  // === 간단한 월별 메모리 캐시 ===
  // key = 'YYYY-MM'
  final Map<String, List<Map<String, dynamic>>> _monthCache = {};
  // (선택) 캐시 사이즈 제한
  static const int _cacheMaxEntries = 6;

  String _ymKey(int y, int m) =>
      '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}';

  Uri _u(String path, [Map<String, String>? q]) {
    final uri = Uri.parse('$baseUrl$path');
    return q == null ? uri : uri.replace(queryParameters: q);
  }

  // lib/features/calendar/calendar_service.dart

  Future<List<Map<String, dynamic>>> _httpGetJsonFlat({
    required int year,
    required int month,
  }) async {
    final uri = _u('/record/records/calendar', {
      'year': year.toString(),
      'month': month.toString(),
    });

    // 🔧 타임아웃 8s → 25s, 재시도 3회 + 지수 백오프
    const int maxRetries = 3;
    const Duration timeout = Duration(seconds: 25);

    http.Response res = http.Response('', 599);
    Object? lastErr;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        res = await client.get(uri).timeout(timeout);
        // 2xx면 통과
        if (res.statusCode ~/ 100 == 2) break;

        // 429/5xx는 재시도, 나머지는 바로 에러
        if (!(res.statusCode == 429 || res.statusCode >= 500)) {
          throw Exception('calendar GET ${res.statusCode}');
        }
      } catch (e) {
        lastErr = e;
      }

      // 백오프 (0.5s, 1s, 2s …)
      final backoffMs = 500 * (1 << attempt);
      await Future.delayed(Duration(milliseconds: backoffMs));
    }

    // 최종 실패 처리
    if (res.statusCode ~/ 100 != 2) {
      if (res.statusCode == 401) {
        throw Exception('calendar GET 401 (Unauthorized)');
      }
      if (lastErr != null) {
        throw lastErr!;
      }
      throw Exception('calendar GET ${res.statusCode}');
    }

    // 무거운 파싱은 그대로 Isolate로
    return compute(parseCalendarMonthIsolate, {
      'rawBody': res.body,
      'year': year,
      'month': month,
    });
  }

  Future<List<Map<String, dynamic>>> _fetchCalendarMonth({
    required int year,
    required int month,
  }) async {
    final key = _ymKey(year, month);

    // 캐시 히트 시 즉시 반환
    final cached = _monthCache[key];
    if (cached != null) return cached;

    final flat = await _httpGetJsonFlat(year: year, month: month);

    // 캐시 업데이트(LRU 비슷하게 사이즈 제한)
    _monthCache[key] = flat;
    if (_monthCache.length > _cacheMaxEntries) {
      _monthCache.remove(_monthCache.keys.first);
    }
    return flat;
  }

  Future<List<Map<String, dynamic>>> fetchCalendarRange({
    required DateTime from,
    required DateTime to,
  }) async {
    return _fetchCalendarMonth(year: from.year, month: from.month);
  }

  // (공용 리스트 유틸: 현재 미사용)
  List<Map<String, dynamic>> _extractList(dynamic body) {
    if (body is List) {
      return body
          .map<Map<String, dynamic>>(
            (e) => e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e as Map),
          )
          .toList();
    }
    if (body is Map && body['data'] is List) {
      final list = body['data'] as List;
      return list
          .map<Map<String, dynamic>>(
            (e) => e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e as Map),
          )
          .toList();
    }
    if (body is Map && body['items'] is List) {
      final list = body['items'] as List;
      return list
          .map<Map<String, dynamic>>(
            (e) => e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e as Map),
          )
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }
}

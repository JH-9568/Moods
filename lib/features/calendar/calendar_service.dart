// lib/features/calendar/calendar_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

typedef JwtProvider = String Function();

class CalendarVisitItem {
  final DateTime date;
  final String spaceName;
  final String? imageUrl;
  final String? durationDisplay;

  CalendarVisitItem({
    required this.date,
    required this.spaceName,
    required this.imageUrl,
    this.durationDisplay,
  });
}

class CalendarDayBucket {
  final DateTime date;
  final List<CalendarVisitItem> items;

  CalendarDayBucket({required this.date, required this.items});
}

class CalendarService {
  final JwtProvider getJwt;
  final http.Client _client;

  CalendarService({required this.getJwt, http.Client? client})
    : _client = client ?? http.Client();

  Future<List<CalendarDayBucket>> fetchRecentVisits() async {
    final uri = Uri.parse('$baseUrl/stats/my/recent-spaces');

    print('[CalendarService] GET $uri'); // ✅ 호출 URL 출력

    final res = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    print('[CalendarService] status: ${res.statusCode}');
    print('[CalendarService] body  : ${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      print('[CalendarService] body: ${res.body}');
      throw Exception('recent-spaces 실패: ${res.statusCode}');
    }

    final map = json.decode(res.body) as Map<String, dynamic>;
    final items = (map['items'] as List? ?? []);

    print('[CalendarService] items length: ${items.length}'); // ✅ 결과 개수

    final parsed = <CalendarVisitItem>[];
    for (final raw in items) {
      final spaceName = (raw['space_name'] ?? '').toString();
      final lastDateStr = (raw['last_visit_date'] ?? '').toString();

      String? imageUrl;
      final dynamic img = raw['space_image_url'];
      if (img is List && img.isNotEmpty) {
        imageUrl = img.first?.toString();
      } else if (img is String && img.trim().isNotEmpty) {
        imageUrl = img;
      }

      DateTime? date;
      if (lastDateStr.isNotEmpty) {
        date = DateTime.tryParse(lastDateStr);
      }
      date ??= DateTime.now();

      parsed.add(
        CalendarVisitItem(
          date: DateTime(date.year, date.month, date.day),
          spaceName: spaceName,
          imageUrl: imageUrl,
          durationDisplay: null,
        ),
      );
    }

    print('[CalendarService] parsed items: ${parsed.length}'); // ✅ 파싱된 결과 개수

    final bucketsMap = <DateTime, List<CalendarVisitItem>>{};
    for (final it in parsed) {
      final key = DateTime(it.date.year, it.date.month, it.date.day);
      bucketsMap.putIfAbsent(key, () => []).add(it);
    }

    final buckets = bucketsMap.entries.map((e) {
      return CalendarDayBucket(date: e.key, items: e.value);
    }).toList();

    buckets.sort((a, b) => a.date.compareTo(b.date));

    print('[CalendarService] bucket count: ${buckets.length}'); // ✅ 날짜 그룹 개수

    return buckets;
  }
}

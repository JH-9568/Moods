// lib/features/home/widget/home_record/home_record_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

/// 외부에서 최신 JWT를 주입받기 위한 타입(현재 B방식에서는 사용 안 하지만 시그니처 유지)
typedef JwtProvider = String Function();

class RecentSpace {
  final String spaceId;
  final String spaceName;
  final String? spaceImageUrl;
  final String? lastVisitDateText; // "2025-08-21"
  final String? lastVisitTimeText; // "2025-08-21T17:53:19"

  const RecentSpace({
    required this.spaceId,
    required this.spaceName,
    required this.spaceImageUrl,
    required this.lastVisitDateText,
    required this.lastVisitTimeText,
  });

  /// 편의: DateTime 파싱 (실패 시 null)
  DateTime? get lastVisitDate =>
      lastVisitDateText == null ? null : DateTime.tryParse(lastVisitDateText!);
  DateTime? get lastVisitTime =>
      lastVisitTimeText == null ? null : DateTime.tryParse(lastVisitTimeText!);

  factory RecentSpace.fromJson(Map<String, dynamic> j) {
    return RecentSpace(
      spaceId: (j['space_id'] ?? '').toString(),
      spaceName: (j['space_name'] ?? '').toString(),
      spaceImageUrl: j['space_image_url']?.toString(),
      lastVisitDateText: j['last_visit_date']?.toString(),
      lastVisitTimeText: j['last_visit_time']?.toString(),
    );
  }
}

class HomeRecordService {
  final JwtProvider jwtProvider;
  final http.Client _client;
  HomeRecordService({required this.jwtProvider, http.Client? client})
    : _client = client ?? http.Client();

  Map<String, String> get _headers {
    // B 방식: AuthHttpClient가 Authorization을 붙여주므로 여기서는 옵션
    final token = jwtProvider();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) h['Authorization'] = token;
    return h;
  }

  Uri _u(String p) => Uri.parse('$baseUrl$p');

  /// GET /stats/my/recent-spaces
  /// 응답 예시:
  /// {
  ///   "success": true,
  ///   "items": [
  ///     {
  ///       "space_id": "...",
  ///       "space_name": "...",
  ///       "space_image_url": null,
  ///       "last_visit_date": "2025-08-21",
  ///       "last_visit_time": "2025-08-21T17:53:19"
  ///     }, ...
  ///   ],
  ///   "total_count": 2
  /// }
  Future<List<RecentSpace>> fetchRecentSpaces() async {
    final res = await _client.get(
      _u('/stats/my/recent-spaces'),
      headers: _headers,
    );
    print(
      '[HomeRecordService] GET ${_u('/stats/my/recent-spaces')} status=${res.statusCode}',
    );
    print('[HomeRecordService] body=${res.body}');
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('최근 방문 공간 호출 실패: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> map =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List items = (map['items'] ?? []) as List;

    // 최신 순서가 보장되지 않으면 lastVisitTime 기준으로 내림차순 정렬
    final list = items
        .whereType<Map>()
        .map((e) => RecentSpace.fromJson(e.cast<String, dynamic>()))
        .toList();

    list.sort((a, b) {
      final at =
          a.lastVisitTime ??
          a.lastVisitDate ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bt =
          b.lastVisitTime ??
          b.lastVisitDate ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at); // 내림차순(최신 우선)
    });

    return list;
  }
}

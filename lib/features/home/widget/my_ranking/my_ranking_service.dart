// lib/features/home/widget/my_ranking/my_ranking_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

typedef JwtProvider = String Function();

/// 서버는 필드명을 my_total_minutes 로 주지만,
/// 실제 값은 "초(seconds)" 로 들어오는 것으로 보임 (현상: 2분 기록 → 2시간 증가).
/// 앱에서는 일괄 "초"로 해석하여 Duration(seconds: …) 로 변환해 사용한다.
class MySpaceRank {
  final String spaceId;
  final String spaceName;
  final String? spaceImageUrl;
  final int userRank;
  final int totalUsers;
  final int myStudyCount;

  /// 서버 raw 값 (이름은 minutes 이지만 실제는 seconds 로 취급)
  final double myTotalRaw; // seconds 로 해석

  final int rankPercentage;

  const MySpaceRank({
    required this.spaceId,
    required this.spaceName,
    required this.spaceImageUrl,
    required this.userRank,
    required this.totalUsers,
    required this.myStudyCount,
    required this.myTotalRaw, // seconds
    required this.rankPercentage,
  });

  /// UI에서 바로 쓸 누적 시간 (초 기반)
  Duration get totalDuration =>
      Duration(seconds: myTotalRaw.isNaN ? 0 : myTotalRaw.round());

  factory MySpaceRank.fromJson(Map<String, dynamic> j) {
    final raw = j['my_total_minutes']; // 서버 명칭 그대로
    final rawNum = (raw is num)
        ? raw.toDouble()
        : double.tryParse('$raw') ?? 0.0;

    return MySpaceRank(
      spaceId: (j['space_id'] ?? '').toString(),
      spaceName: (j['space_name'] ?? '').toString(),
      spaceImageUrl: j['space_image_url']?.toString(),
      userRank: (j['user_rank'] ?? 0) as int,
      totalUsers: (j['total_users'] ?? 0) as int,
      myStudyCount: (j['my_study_count'] ?? 0) as int,
      // 초 단위 누적 시간을 그대로 저장
      myTotalRaw: rawNum,
      rankPercentage: (j['rank_percentage'] ?? 0) as int,
    );
  }
}

class MyRankingService {
  final http.Client _client;
  final JwtProvider? jwtProvider; // (AuthHttpClient 쓰면 옵션)

  MyRankingService({http.Client? client, this.jwtProvider})
    : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final t = jwtProvider?.call() ?? '';
    final h = <String, String>{'Content-Type': 'application/json'};
    if (t.isNotEmpty) h['Authorization'] = t;
    return h;
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  /// GET /stats/my/spaces-ranks
  Future<List<MySpaceRank>> fetchMySpacesRanks() async {
    final res = await _client.get(
      _u('/stats/my/spaces-ranks'),
      headers: _headers,
    );
    print(
      '[MyRankingService] GET ${_u('/stats/my/spaces-ranks')} status=${res.statusCode}',
    );
    print('[MyRankingService] body=${res.body}');
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('나의 공간 랭킹 호출 실패: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> data =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List items = (data['items'] ?? []) as List;

    final list = items
        .whereType<Map>()
        .map((e) => MySpaceRank.fromJson(e.cast<String, dynamic>()))
        .toList();

    // 총 시간(초 기반) 내림차순 정렬 (1등이 가장 앞)
    list.sort((a, b) => b.myTotalRaw.compareTo(a.myTotalRaw));
    return list;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';
import 'package:moods/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 외부에서 최신 JWT를 주입받기 위한 타입
typedef JwtProvider = String Function();

/// API 응답 모델
class MySpaceRank {
  final String spaceId;
  final String spaceName;
  final String? spaceImageUrl;
  final int userRank;
  final int totalUsers;
  final int myStudyCount;
  final double myTotalMinutes; // 서버가 실수(minutes)로 내려줌
  final int rankPercentage;

  const MySpaceRank({
    required this.spaceId,
    required this.spaceName,
    required this.spaceImageUrl,
    required this.userRank,
    required this.totalUsers,
    required this.myStudyCount,
    required this.myTotalMinutes,
    required this.rankPercentage,
  });

  Duration get totalDuration =>
      Duration(minutes: myTotalMinutes.isNaN ? 0 : myTotalMinutes.round());

  factory MySpaceRank.fromJson(Map<String, dynamic> j) => MySpaceRank(
    spaceId: (j['space_id'] ?? '').toString(),
    spaceName: (j['space_name'] ?? '').toString(),
    spaceImageUrl: j['space_image_url']?.toString(),
    userRank: (j['user_rank'] ?? 0) as int,
    totalUsers: (j['total_users'] ?? 0) as int,
    myStudyCount: (j['my_study_count'] ?? 0) as int,
    myTotalMinutes: (j['my_total_minutes'] is num)
        ? (j['my_total_minutes'] as num).toDouble()
        : double.tryParse('${j['my_total_minutes']}') ?? 0.0,
    rankPercentage: (j['rank_percentage'] ?? 0) as int,
  );
}

/// Riverpod Provider: 서비스 인스턴스 주입
/// - 매 호출 시점에 최신 JWT를 가져와 Authorization 헤더에 "Bearer {token}" 형식으로 넣습니다.
/// - 토큰이 없으면(또는 만료 등) 빈 문자열을 반환하여 Authorization 헤더를 생략합니다.
final myRankingServiceProvider = Provider<MyRankingService>(
  (ref) {
    return MyRankingService(
      jwtProvider: () {
        final t = ref.watch(authTokenProvider); // 토큰 변화에 반응
        return (t == null || t.isEmpty) ? '' : 'Bearer $t';
      },
    );
  },
  dependencies: [authTokenProvider], // ★ 추가
);

class MyRankingService {
  final JwtProvider jwtProvider;
  final http.Client _client;
  MyRankingService({required this.jwtProvider, http.Client? client})
    : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final token = jwtProvider();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) h['Authorization'] = token;
    return h;
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  /// GET /stats/my/spaces-ranks
  Future<List<MySpaceRank>> fetchMySpacesRanks() async {
    final res = await _client.get(
      _u('/stats/my/spaces-ranks'),
      headers: _headers,
    );
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

    // 혹시 서버가 정렬 보장 안 해줄 때를 대비해, 누적 분 내림차순 정렬
    list.sort((a, b) => b.myTotalMinutes.compareTo(a.myTotalMinutes));
    return list;
  }
}

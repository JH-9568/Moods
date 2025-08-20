// lib/features/record/service/record_service.dart
// 서비스: 백엔드 API 호출 담당
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart'; // baseUrl 상수

/// jwtProvider는 "Bearer <token>"을 그대로 반환해야 함.
class RecordService {
  final String Function() jwtProvider;
  const RecordService({required this.jwtProvider});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': jwtProvider(),
      };

  Uri _u(String path, [Map<String, String>? q]) {
    final uri = Uri.parse('$baseUrl$path');
    return q == null ? uri : uri.replace(queryParameters: q);
  }

  // 1) 세션 시작
  Future<Map<String, dynamic>> startSession({
    required String mood,
    required List<String> goals,
    required String title,
    required String spaceId,
    required String emotion,
    required List<String> spaceFeature,
  }) async {
    final res = await http.post(
      _u('/study-sessions/start'),
      headers: _headers,
      body: jsonEncode({
        'mood': mood,
        'goals': goals,
        'title': title,
        'space_id': spaceId,
        'emotion': emotion,
        'space_feature': spaceFeature,
      }),
    );
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 시작 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // 2) 일시중지
  Future<Map<String, dynamic>> pauseSession() async {
    final res = await http.get(_u('/study-sessions/pause'), headers: _headers);
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 일시중지 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // 3) 재개
  Future<Map<String, dynamic>> resumeSession() async {
    final res = await http.get(_u('/study-sessions/resume'), headers: _headers);
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 재개 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // 4) 종료
  Future<Map<String, dynamic>> finishSession() async {
    final res = await http.get(_u('/study-sessions/finish'), headers: _headers);
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 종료 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // 5) 종료 세션을 기록으로 내보내기
  Future<Map<String, dynamic>> exportToRecord() async {
    final res = await http.post(_u('/study-sessions/session-to-record'), headers: _headers);
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 기록 내보내기 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // === Goals ===

  // 목표 추가 (POST /study-sessions/goals)
  Future<Map<String, dynamic>> addGoal(String text, {bool done = false}) async {
    final res = await http.post(
      _u('/study-sessions/goals'),
      headers: _headers,
      body: jsonEncode({'text': text, 'done': done}),
    );
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('목표 추가 실패: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception('목표 추가 실패(success=false): ${res.body}');
    }
    return data;
  }

  // 목표 완료 토글 (PATCH /study-sessions/goals/:index)
  Future<Map<String, dynamic>> toggleGoal(int index, bool done) async {
    final res = await http.patch(
      _u('/study-sessions/goals/$index'),
      headers: _headers,
      body: jsonEncode({'done': done}),
    );
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('목표 토글 실패: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception('목표 토글 실패(success=false): ${res.body}');
    }
    return data;
  }

  // 목표 제거 (DELETE /study-sessions/goals/:index)
  Future<Map<String, dynamic>> removeGoal(int index) async {
    final res = await http.delete(
      _u('/study-sessions/goals/$index'),
      headers: _headers,
    );
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('목표 삭제 실패: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception('목표 삭제 실패(success=false): ${res.body}');
    }
    return data;
  }

  // 7) 무드 기반 배경 이미지 URL 조회
  // moodQuery 값: '트렌디한','감성적인','개방적인','자연 친화적인','컨셉 있는','활기찬','아늑한','조용한'
  Future<String> fetchWallpaper(String moodQuery) async {
    final res = await http.get(
      _u('/photos/wallpaper', {'query': moodQuery}),
      headers: _headers,
    );
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('배경사진 불러오기 실패: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final url = (data['data'] ?? const {})['url'] as String?;
    if (data['success'] == true && url != null && url.isNotEmpty) {
      return url;
    }
    throw Exception('배경사진 응답 파싱 실패: ${res.body}');
  }
}

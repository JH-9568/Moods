// lib/features/record/service/record_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

class RecordService {
  final http.Client client;
  const RecordService({required this.client});

  Map<String, String> get _jsonHeaders => const {
        'Content-Type': 'application/json',
      };

  Uri _u(String path, [Map<String, String>? q]) {
    final uri = Uri.parse('$baseUrl$path');
    return q == null ? uri : uri.replace(queryParameters: q);
  }

  // ===== Sessions =====

  // 1) 세션 시작
  Future<Map<String, dynamic>> startSession({
    required String moodId,
    required List<String> goals,
  }) async {
    final body = jsonEncode({
      'mood_id': moodId.isEmpty ? <String>[] : <String>[moodId],
      'goals': goals,
    });

    final res = await client.post(
      _u('/study-sessions/start'),
      headers: _jsonHeaders,
      body: body,
    );
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 시작 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // 2) 일시중지
  Future<Map<String, dynamic>> pauseSession() async {
    final res = await client.get(_u('/study-sessions/pause'), headers: _jsonHeaders);
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 일시중지 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // 3) 재개
  Future<Map<String, dynamic>> resumeSession() async {
    final res = await client.get(_u('/study-sessions/resume'), headers: _jsonHeaders);
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 재개 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // 4) 종료
  Future<Map<String, dynamic>> finishSession() async {
    final res = await client.get(_u('/study-sessions/finish'), headers: _jsonHeaders);
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 종료 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

 // 5) 종료 세션을 기록으로 내보내기 (feedback_id 절대 전송 X)
// import 'dart:convert';  // 꼭 있어야 합니다.

/// 5) 종료 세션을 기록으로 내보내기
/// - 기본은 feedback_id 전송하지 않음
/// - 넘어온 feedbackId가 있더라도 'undefined' 이거나 UUID 형식이 아니면 제거
Future<Map<String, dynamic>> exportToRecord({
  required String title,
  required List<String> emotionTagIds,
  required String spaceId,
  int? wifiScore,
  int? noiseLevel,
  int? crowdness,
  bool? power,
}) async {
  // 감정 태그 정리: trim + 중복 제거 + 빈값 제거
  final cleanTags = <String>{
    for (final t in emotionTagIds) t.trim(),
  }.where((e) => e.isNotEmpty).toList();

  // payload 구성 (null은 넣지 않음)
  final body = <String, dynamic>{
    'title': title.trim(),
    'emotion_tag_ids': cleanTags,
    'space_id': spaceId.trim(),
    if (wifiScore != null)  'wifi_score':  wifiScore,
    if (noiseLevel != null) 'noise_level': noiseLevel,
    if (crowdness != null)  'crowdness':   crowdness,
    if (power != null)      'power':       power,
    // ❌ 'feedback_id' 절대 추가 금지
  };
  final res = await client.post(
    _u('/study-sessions/session-to-record'),
    headers: _jsonHeaders, // Authorization은 AuthHttpClient가 주입
    body: jsonEncode(body),
  );

  if (res.statusCode ~/ 100 != 2) {
    throw Exception('세션 기록 내보내기 실패: ${res.body}');
  }

  return jsonDecode(res.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>?> fetchSpaceDetail(String spaceId) async {
  if (spaceId.trim().isEmpty) return null;

  final res = await client.get(
    _u('/spaces/detail', {'space_id': spaceId}),
    headers: _jsonHeaders,
  );
  if (res.statusCode ~/ 100 != 2) {
    throw Exception('공간 상세 조회 실패: ${res.statusCode} ${res.body}');
  }

  final body = jsonDecode(res.body) as Map<String, dynamic>;
  final list = (body['data'] as List? ?? const []);
  if (list.isEmpty) return null;
  return Map<String, dynamic>.from(list.first as Map);
}


 Future<bool> quitSession() async {
    final res = await client.get(
      _u('/study-sessions/quit'),
      headers: _jsonHeaders, // Authorization은 AuthHttpClient가 넣어줌
    );

    // 세션이 없을 때 404를 정상 취소로 간주 (Postman엔 항상 200 예시)
    if (res.statusCode == 404) return true;

    // 2xx면 성공으로 처리 (바디가 비어있을 수도 있음)
    if (res.statusCode ~/ 100 == 2) {
      if (res.body.isEmpty) return true;
      final body = jsonDecode(res.body);
      if (body is Map && body['success'] == true) return true;
      // success 필드 없으면 일단 성공 취급
      return true;
    }

    throw Exception('세션 취소(quit) 실패: ${res.statusCode} ${res.body}');
  }



  // 사용자의 현재 활성 세션 조회
  Future<Map<String, dynamic>?> fetchUserSession() async {
    final res = await client.get(_u('/study-sessions/user-session'), headers: _jsonHeaders);
    if (res.statusCode == 404) return null;
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('사용자 세션 조회 실패: ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return null;
  }

  // ===== Moods =====
  /// 공간무드 패치 (개수 제한 없음)
  Future<Map<String, dynamic>> updateSessionMood(List<String> moods) async {
    // trim + 빈값 제거 + 중복 제거(순서 유지)
    final cleaned = <String>[];
    for (final m in moods) {
      final s = m.trim();
      if (s.isEmpty) continue;
      if (!cleaned.contains(s)) cleaned.add(s);
    }

    final res = await client.patch(
      _u('/study-sessions/mood'),
      headers: _jsonHeaders,
      body: jsonEncode({'mood_id': cleaned}),
    );

    if (res.statusCode ~/ 100 != 2) {
      throw Exception('공간무드 업데이트 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ===== Goals =====

  Future<Map<String, dynamic>> addGoal(String text, {bool done = false}) async {
    final res = await client.post(
      _u('/study-sessions/goals'),
      headers: _jsonHeaders,
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

  Future<Map<String, dynamic>> toggleGoal(int index, bool done) async {
    final res = await client.patch(
      _u('/study-sessions/goals/$index'),
      headers: _jsonHeaders,
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

  Future<Map<String, dynamic>> removeGoal(int index) async {
    final res = await client.delete(
      _u('/study-sessions/goals/$index'),
      headers: _jsonHeaders,
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

  // ===== Wallpaper =====

  Future<String> fetchWallpaper(String moodQuery) async {
    final res = await client.get(
      _u('/photos/wallpaper', {'query': moodQuery}),
      headers: _jsonHeaders,
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

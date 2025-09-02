// lib/features/record/service/record_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart'; 
/// jwtProvider는 "Bearer <token>" 형태의 문자열을 반환해야 함.
class RecordService {
  final String Function() jwtProvider;
  const RecordService({required this.jwtProvider});

  Map<String, String> get _headers {
    final raw = jwtProvider().trim(); // providers에서 'Bearer <token>' 들어옴 가정
    final hasAuth = raw.isNotEmpty && raw.toLowerCase().startsWith('bearer ');

    // 디버그 로그(마스킹)
    final masked = raw.isEmpty
        ? '""'
        : '${raw.substring(0, raw.length.clamp(0, 12))}•••';
    print('3️⃣ record_service.dart: Creating headers. Authorization value is: $masked');

    return {
      'Content-Type': 'application/json',
      if (hasAuth) 'Authorization': raw, // 🔥 빈값이면 아예 헤더를 넣지 말기
    };
  }

  Uri _u(String path, [Map<String, String>? q]) {
    final uri = Uri.parse('$baseUrl$path');
    return q == null ? uri : uri.replace(queryParameters: q);
  }

  // ===== Sessions =====

  // 1) 세션 시작 (Postman 명세 기준 수정)
  // Postman 명세에 따라 mood_id와 goals만 받도록 수정했습니다.
  Future<Map<String, dynamic>> startSession({
    required String moodId,
    required List<String> goals,
  }) async {
    final body = {
      'mood_id': moodId.isEmpty ? <String>[] : <String>[moodId],
      'goals': goals,
    };

    final res = await http.post(
      _u('/study-sessions/start'),
      headers: _headers,
      body: jsonEncode(body),
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

  // 5) 종료 세션을 기록으로 내보내기 (Postman 명세 기준 수정)
  // Postman 명세에 따라 필요한 모든 정보를 body에 담아 보내도록 수정했습니다.
  Future<Map<String, dynamic>> exportToRecord({
    required String title,
    required List<String> emotionTagIds,
    required String spaceId,
    int? wifiScore,
    int? noiseLevel,
    int? crowdness,
    bool? power,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'emotion_tag_ids': emotionTagIds,
      'space_id': spaceId,
      'wifi_score': wifiScore,
      'noise_level': noiseLevel,
      'crowdness': crowdness,
      'power': power,
    };
    // body에서 null 값은 제외
    body.removeWhere((key, value) => value == null);
    
    final res = await http.post(
      _u('/study-sessions/session-to-record'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 기록 내보내기 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
  
  // 사용자의 현재 활성 세션 조회
  Future<Map<String, dynamic>?> fetchUserSession() async {
  final res = await http.get(_u('/study-sessions/user-session'), headers: _headers);
  if (res.statusCode == 404) return null;
  if (res.statusCode ~/ 100 != 2) {
    throw Exception('사용자 세션 조회 실패: ${res.body}');
  }

  final data = jsonDecode(res.body);
  if (data is Map && data['data'] is Map) {
    final session = data['data'] as Map<String, dynamic>;
    return session;
  }

  return null;
}

  // ===== Goals =====

  // 목표 추가
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

  // 목표 토글
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

  // 목표 제거
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

  // ===== Wallpaper =====

  // 무드 기반 배경 이미지 URL 조회
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
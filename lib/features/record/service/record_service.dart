import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

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

  Future<Map<String, dynamic>> pauseSession() async {
    final res =
        await client.get(_u('/study-sessions/pause'), headers: _jsonHeaders);
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 일시중지 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resumeSession() async {
    final res =
        await client.get(_u('/study-sessions/resume'), headers: _jsonHeaders);
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 재개 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> finishSession() async {
    final res =
        await client.get(_u('/study-sessions/finish'), headers: _jsonHeaders);
    if (res.statusCode ~/ 100 != 2) {
      throw Exception('세션 종료 실패: ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// 종료 세션을 기록으로 내보내기
  Future<Map<String, dynamic>> exportToRecord({
    required String title,
    required List<String> emotionTagIds,
    required String spaceId,
    int? wifiScore,
    int? noiseLevel,
    int? crowdness,
    bool? power,
  }) async {
    final cleanTags = <String>{
      for (final t in emotionTagIds) t.trim(),
    }.where((e) => e.isNotEmpty).toList();

    final body = <String, dynamic>{
      'title': title.trim(),
      'emotion_tag_ids': cleanTags,
      'space_id': spaceId.trim(),
      if (wifiScore != null) 'wifi_score': wifiScore,
      if (noiseLevel != null) 'noise_level': noiseLevel,
      if (crowdness != null) 'crowdness': crowdness,
      if (power != null) 'power': power,
    };

    final res = await client.post(
      _u('/study-sessions/session-to-record'),
      headers: _jsonHeaders,
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

  /// 사진 업로드 (form-data, field: "file")
  /// - Content-Type 헤더를 수동 설정하지 않음 (boundary 자동)
  /// - bearerToken 전달 시 Authorization 부여
  Future<Map<String, dynamic>> uploadRecordPhoto({
    required String recordId,
    required File file,
    String? bearerToken,
  }) async {
    final uri = _u('/photos/records/$recordId');
    final req = http.MultipartRequest('POST', uri);

    if (bearerToken != null && bearerToken.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $bearerToken';
    }
    req.headers['Accept'] = 'application/json';

    final bytes = await file.readAsBytes();
    final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
    final parts = mime.split('/');
    final mt = parts.length == 2 ? MediaType(parts[0], parts[1]) : null;

    req.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: p.basename(file.path),
      contentType: mt,
    ));

    // 전역 client가 Content-Type을 덮어쓸 수 있으므로 직접 send()
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode ~/ 100 != 2) {
      throw Exception('사진 업로드 실패: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<bool> quitSession() async {
    final res = await client.get(
      _u('/study-sessions/quit'),
      headers: _jsonHeaders,
    );

    if (res.statusCode == 404) return true;

    if (res.statusCode ~/ 100 == 2) {
      if (res.body.isEmpty) return true;
      final body = jsonDecode(res.body);
      if (body is Map && body['success'] == true) return true;
      return true;
    }

    throw Exception('세션 취소(quit) 실패: ${res.statusCode} ${res.body}');
  }

  // 기록카드 상세 조회
  Future<Map<String, dynamic>> fetchRecordDetail(String recordId) async {
    if (recordId.trim().isEmpty) {
      throw ArgumentError('recordId is empty');
    }

    final res = await client.get(
      _u('/record/records/$recordId'),
      headers: _jsonHeaders,
    );

    if (res.statusCode ~/ 100 != 2) {
      throw Exception('기록카드 상세 조회 실패: ${res.statusCode} ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body;
  }

  // 사용자의 현재 활성 세션 조회
  Future<Map<String, dynamic>?> fetchUserSession() async {
    final res =
        await client.get(_u('/study-sessions/user-session'), headers: _jsonHeaders);
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
  Future<Map<String, dynamic>> updateSessionMood(List<String> moods) async {
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

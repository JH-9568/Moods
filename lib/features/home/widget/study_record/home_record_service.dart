// lib/features/home/widget/study_record/home_record_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart';

typedef JwtProvider = String Function();

class RecentSpace {
  final String spaceId;
  final String spaceName;
  final String? spaceImageUrl;
  final String? lastVisitDateText;
  final String? lastVisitTimeText;

  /// 항상 '초'만 저장
  final int? durationSeconds;

  const RecentSpace({
    required this.spaceId,
    required this.spaceName,
    required this.spaceImageUrl,
    required this.lastVisitDateText,
    required this.lastVisitTimeText,
    this.durationSeconds,
  });

  DateTime? get lastVisitDate =>
      lastVisitDateText == null ? null : DateTime.tryParse(lastVisitDateText!);
  DateTime? get lastVisitTime =>
      lastVisitTimeText == null ? null : DateTime.tryParse(lastVisitTimeText!);

  /// 표시용 (“2시간 30분”, “35초” 등)
  String get durationKorean {
    if (durationSeconds == null) return '';
    final total = durationSeconds!.clamp(0, 999999999);
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;

    if (h > 0 && m > 0) return '${h}시간 ${m}분';
    if (h > 0) return '${h}시간';
    if (m > 0 && s > 0) return '${m}분 ${s}초';
    if (m > 0) return '${m}분';
    return '${s}초';
  }

  static String? _pickImage(dynamic v) {
    if (v is List && v.isNotEmpty) return v.first?.toString();
    if (v is String && v.trim().isNotEmpty) return v;
    return null;
  }

  /// 어떤 입력이 와도 '초'로 통일
  static int? _toSeconds(dynamic raw) {
    if (raw == null) return null;

    // Map 형태: {seconds: 9000} or {hours: 2.5}
    if (raw is Map) {
      final sec = raw['seconds'] ?? raw['sec'];
      final hrs = raw['hours'] ?? raw['hour'];
      if (sec != null) return _toSeconds(sec);
      if (hrs != null)
        return ((double.tryParse(hrs.toString()) ?? 0) * 1).round();
      // 다른 키가 있다면 필요 시 추가
      return null;
    }

    // 정수 → 초
    if (raw is int) return raw;

    // 실수 → "시간"으로 간주해 초로 변환 (API가 9.52 같은 걸 주는 케이스)
    if (raw is double) return (raw * 1).round();

    if (raw is String) {
      final s = raw.trim();

      // HH:MM[:SS]
      if (s.contains(':')) {
        final parts = s.split(':').map((e) => int.tryParse(e) ?? 0).toList();
        final h = parts.isNotEmpty ? parts[0] : 0;
        final m = parts.length > 1 ? parts[1] : 0;
        final sec = parts.length > 2 ? parts[2] : 0;
        return h * 3600 + m * 60 + sec;
      }

      // 정수 문자열 → 초
      if (RegExp(r'^\d+$').hasMatch(s)) {
        return int.tryParse(s);
      }

      // 소수 문자열 → 시간으로 간주해 초로
      if (RegExp(r'^\d+(\.\d+)?$').hasMatch(s)) {
        final hrs = double.tryParse(s) ?? 0.0;
        return (hrs * 3600).round();
      }

      // "2시간 30분 10초" 같은 한글
      final h = RegExp(r'(\d+)\s*시간').firstMatch(s)?.group(1);
      final m = RegExp(r'(\d+)\s*분').firstMatch(s)?.group(1);
      final sec = RegExp(r'(\d+)\s*초').firstMatch(s)?.group(1);
      final hh = int.tryParse(h ?? '0') ?? 0;
      final mm = int.tryParse(m ?? '0') ?? 0;
      final ss = int.tryParse(sec ?? '0') ?? 0;
      if (hh > 0 || mm > 0 || ss > 0) {
        return hh * 3600 + mm * 60 + ss;
      }
    }

    return null;
  }

  factory RecentSpace.fromJson(Map<String, dynamic> j) {
    // duration 후보 키들 (응답에 맞춰 자유롭게 추가)
    final raw =
        j['duration'] ??
        j['duration_seconds'] ??
        j['study_duration_seconds'] ??
        j['study_duration'] ??
        j['total_duration_seconds'] ??
        j['total_seconds'] ??
        j['study_time_seconds'] ??
        j['study_total_seconds'];

    final seconds = _toSeconds(raw);

    // 디버그: 실제 값/타입 확인
    // print('[RecentSpace] rawDur=$raw (${raw.runtimeType}) -> sec=$seconds name=${j['space_name']}');

    return RecentSpace(
      spaceId: (j['space_id'] ?? '').toString(),
      spaceName: (j['space_name'] ?? '').toString(),
      spaceImageUrl: _pickImage(j['space_image_url']),
      lastVisitDateText: j['last_visit_date']?.toString(),
      lastVisitTimeText: j['last_visit_time']?.toString(),
      durationSeconds: seconds,
    );
  }
}

class HomeRecordService {
  final JwtProvider jwtProvider;
  final http.Client _client;
  HomeRecordService({required this.jwtProvider, http.Client? client})
    : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final token = jwtProvider();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) h['Authorization'] = token;
    return h;
  }

  Uri _u(String p) => Uri.parse('$baseUrl$p');

  Future<List<RecentSpace>> fetchRecentSpaces() async {
    final uri = _u('/stats/my/recent-spaces');
    print('[HomeRecordService] ▶️ 요청 시작: $uri');

    final res = await _client.get(uri, headers: _headers);

    // 상태 코드와 길이를 무조건 찍기
    print(
      '[HomeRecordService] ◀️ 응답 status=${res.statusCode} length=${res.body.length}',
    );

    // 필요하면 본문도 같이
    print('[HomeRecordService] body=${res.body}');

    if (res.statusCode ~/ 100 != 2) {
      throw Exception('최근 방문 공간 호출 실패: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> map =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List items = (map['items'] ?? []) as List;

    // duration 확인 로그
    for (final e in items) {
      if (e is Map) {
        final m = e.cast<String, dynamic>();
        final d =
            m['duration'] ??
            m['duration_seconds'] ??
            m['study_duration_seconds'] ??
            m['study_duration'] ??
            m['total_duration_seconds'] ??
            m['total_seconds'] ??
            m['study_time_seconds'] ??
            m['study_total_seconds'];
        print(
          '[HomeRecordService] raw duration=$d (${d?.runtimeType}) name=${m['space_name']}',
        );
      }
    }

    final list = items
        .whereType<Map>()
        .map((e) => RecentSpace.fromJson(e.cast<String, dynamic>()))
        .toList();

    for (final it in list) {
      print(
        '[HomeRecordService] "${it.spaceName}" seconds=${it.durationSeconds} label="${it.durationKorean}"',
      );
    }

    list.sort((a, b) {
      final at =
          a.lastVisitTime ??
          a.lastVisitDate ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bt =
          b.lastVisitTime ??
          b.lastVisitDate ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    return list;
  }
}

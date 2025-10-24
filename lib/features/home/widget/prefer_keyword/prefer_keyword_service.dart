import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:moods/common/constants/api_constants.dart'; // baseUrl

/// 단일 키워드 모델
class PreferKeyword {
  final String label;
  final int? count;
  final String? id;

  const PreferKeyword({required this.label, this.count, this.id});

  static PreferKeyword fromDynamic(dynamic v) {
    if (v is String) {
      final t = v.trim();
      return PreferKeyword(label: t.isEmpty ? '-' : t);
    }
    if (v is Map<String, dynamic>) {
      final label =
          (v['label'] ?? v['name'] ?? v['keyword'] ?? v['title'] ?? '')
              .toString()
              .trim();
      final id = (v['id'] ?? v['_id'] ?? v['key'])?.toString();
      final raw = v['count'] ?? v['freq'] ?? v['frequency'];
      final count = raw is num ? raw.toInt() : null;
      return PreferKeyword(
        label: label.isEmpty ? '-' : label,
        count: count,
        id: id,
      );
    }
    return PreferKeyword(label: v?.toString() ?? '-');
  }
}

/// 3가지 묶음
class PreferKeywordBundle {
  final List<PreferKeyword> types;
  final List<PreferKeyword> moods;
  final List<PreferKeyword> features;

  const PreferKeywordBundle({
    this.types = const [],
    this.moods = const [],
    this.features = const [],
  });

  static List<PreferKeyword> _list(dynamic raw) => raw is List
      ? raw.map((e) => PreferKeyword.fromDynamic(e)).toList()
      : const [];

  /// 다양한 응답 케이스 흡수 (root, data, items, keywords 등)
  factory PreferKeywordBundle.fromAny(dynamic body) {
    final root = body is Map<String, dynamic>
        ? body
        : const <String, dynamic>{};

    dynamic pick(Map<String, dynamic> map, List<String> keys) {
      for (final k in keys) {
        if (map[k] != null) return map[k];
      }
      return null;
    }

    // 1차 후보: root
    var types = _list(pick(root, ['types', 'type']));
    var moods = _list(pick(root, ['moods', 'mood']));
    var features = _list(pick(root, ['features', 'feature']));

    // 2차 후보: data / items / keywords 객체 안
    if (types.isEmpty && moods.isEmpty && features.isEmpty) {
      final containers = <dynamic>[
        root['data'],
        root['items'],
        root['keywords'],
        root['preferred'],
        root['preferred_keywords'],
      ];
      for (final c in containers) {
        if (c is Map<String, dynamic>) {
          types = _list(pick(c, ['types', 'type']));
          moods = _list(pick(c, ['moods', 'mood']));
          features = _list(pick(c, ['features', 'feature']));
          if (types.isNotEmpty || moods.isNotEmpty || features.isNotEmpty)
            break;
        }
      }
    }

    // 특수 케이스: [{type:..}, {mood:..}, {feature:..}] 형태
    if (types.isEmpty && moods.isEmpty && features.isEmpty) {
      final maybeList =
          root['keywords'] ?? root['preferred'] ?? root['preferred_keywords'];
      if (maybeList is List) {
        final t = <PreferKeyword>[],
            m = <PreferKeyword>[],
            f = <PreferKeyword>[];
        for (final e in maybeList) {
          if (e is Map<String, dynamic>) {
            if (e['type'] != null) t.add(PreferKeyword.fromDynamic(e['type']));
            if (e['mood'] != null) m.add(PreferKeyword.fromDynamic(e['mood']));
            if (e['feature'] != null)
              f.add(PreferKeyword.fromDynamic(e['feature']));
          }
        }
        return PreferKeywordBundle(types: t, moods: m, features: f);
      }
    }

    return PreferKeywordBundle(types: types, moods: moods, features: features);
  }
}

class PreferKeywordService {
  final http.Client client;
  PreferKeywordService({required this.client});

  Uri get _url => Uri.parse('$baseUrl/stats/my/preferred-keywords');

  /// 중복 요청 방지용 인플라이트 Future
  Future<PreferKeywordBundle>? _inflight;

  Future<PreferKeywordBundle> fetchAll() {
    if (_inflight != null) return _inflight!;
    _inflight = _doFetch().whenComplete(() => _inflight = null);
    return _inflight!;
  }

  Future<PreferKeywordBundle> _doFetch() async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[PreferKeyword] GET $_url');
    }

    // Authorization 헤더는 authHttpClientProvider가 자동 부착
    final headers = const {'Content-Type': 'application/json'};

    http.Response res;
    try {
      res = await client.get(_url, headers: headers);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[PreferKeyword] ❌ Network failed: $e');
      }
      throw Exception('Network error: $e');
    }

    if (kDebugMode) {
      final preview = res.body.length > 600
          ? '${res.body.substring(0, 600)}…'
          : res.body;
      // ignore: avoid_print
      print(
        '[PreferKeyword] <${res.statusCode}> ${res.reasonPhrase} | $preview',
      );
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode} ${res.reasonPhrase}');
    }

    if (res.body.isEmpty) return const PreferKeywordBundle();

    try {
      final body = jsonDecode(res.body);
      return PreferKeywordBundle.fromAny(body);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[PreferKeyword] ❌ JSON decode: $e');
      }
      // 파싱 실패 시 빈값 반환 (UI는 빈 상태로)
      return const PreferKeywordBundle();
    }
  }
}

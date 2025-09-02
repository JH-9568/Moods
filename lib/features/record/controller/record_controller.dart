// lib/features/record/controller/record_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ 추가

import 'package:moods/providers.dart'; // recordServiceProvider, authTokenProvider

// =====================
// 안전 파서 & 상태 매핑 유틸
// =====================
int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool _asBool(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return fallback;
}

DateTime? _asDateTime(dynamic v) {
  if (v == null) return null;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
  if (v is String) {
    final dt = DateTime.tryParse(v);
    return dt?.toUtc();
  }
  return null;
}

List<dynamic> _asList(dynamic v) {
  if (v == null) return const [];
  if (v is List) return v;
  if (v is String) {
    try {
      final decoded = jsonDecode(v);
      if (decoded is List) return decoded;
    } catch (_) {}
  }
  return const [];
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  if (v is String) {
    try {
      final decoded = jsonDecode(v);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return <String, dynamic>{};
}

/// 백이 {success:true, data:{...}} 형태일 때 data 반환, 아니면 그대로
Map<String, dynamic> _rootDataOrSelf(Map<String, dynamic> resp) {
  final data = resp['data'];
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return resp;
}

// ==== session status mapping ====
enum _SessionStatus { running, paused, completed, unknown }

_SessionStatus _mapStatus(dynamic raw) {
  final s = (raw?.toString().toLowerCase() ?? '');
  if (s == 'running') return _SessionStatus.running;
  if (s == 'paused')  return _SessionStatus.paused;
  if (s == 'finished' || s == 'ended' || s == 'complete' || s == 'completed') {
    return _SessionStatus.completed;
  }
  return _SessionStatus.unknown;
}

// =====================
// JWT 만료 체크 유틸(참고용)
// =====================
String? _jwtPayloadBase64(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  return parts[1];
}

bool _isJwtExpired(String token) {
  try {
    final p64 = _jwtPayloadBase64(token);
    if (p64 == null) return true;
    String norm = p64.replaceAll('-', '+').replaceAll('_', '/');
    while (norm.length % 4 != 0) { norm += '='; }
    final payload = jsonDecode(utf8.decode(base64Url.decode(norm)));
    final exp = payload['exp'];
    if (exp is! num) return true;
    final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return nowSec >= (exp.toInt() - 30); // 30s leeway
  } catch (_) {
    return true;
  }
}

// ---------------------
// 오류 문구 패턴
// ---------------------
bool _isAlreadyPausedErr(Object e) {
  final s = e.toString().toLowerCase();
  return (s.contains('이미') && (s.contains('일시') || s.contains('pause')))
      || (s.contains('already') && (s.contains('paused') || s.contains('pause')));
}

bool _isAlreadyRunningErr(Object e) {
  final s = e.toString().toLowerCase();
  return (s.contains('이미') && (s.contains('재개') || s.contains('resume')))
      || (s.contains('already') && (s.contains('running') || s.contains('resum')));
}

// =====================
// StartArgs / GoalItem
// =====================
class StartArgs {
  final String title;
  final List<String> goals;
  final String spaceId;
  final String moodId;
  final List<String> emotionTagIds;
  final int? wifiScore;
  final int? noiseLevel;
  final int? crowdness;
  final bool? power;

  const StartArgs({
    required this.title,
    required this.goals,
    required this.spaceId,
    this.moodId = '',
    this.emotionTagIds = const [],
    this.wifiScore,
    this.noiseLevel,
    this.crowdness,
    this.power,
  });
}

class GoalItem {
  final String text;
  final bool done;
  const GoalItem(this.text, this.done);

  GoalItem copyWith({String? text, bool? done}) =>
      GoalItem(text ?? this.text, done ?? this.done);
}

// =====================
// State
// =====================
class RecordState {
  // 타이머
  final bool isRunning;
  final DateTime? startedAtUtc;
  final int accumulatedPauseSeconds;
  final Duration elapsed;
  final bool isPaused;

  // 세션
  final List<String> selectedMoods;
  final List<GoalItem> goals;
  final String wallpaperUrl;
  final bool hasActiveSession;

  // export 메타
  final String title;
  final String spaceId;
  final List<String> emotionTagIds;
  final int? wifiScore;
  final int? noiseLevel;
  final int? crowdness;
  final bool? power;

  const RecordState({
    this.isRunning = false,
    this.startedAtUtc,
    this.accumulatedPauseSeconds = 0,
    this.elapsed = Duration.zero,
    this.isPaused = false,
    this.selectedMoods = const [],
    this.goals = const [],
    this.wallpaperUrl = '',
    this.hasActiveSession = false,
    this.title = '',
    this.spaceId = '',
    this.emotionTagIds = const [],
    this.wifiScore,
    this.noiseLevel,
    this.crowdness,
    this.power,
  });

  RecordState copyWith({
    bool? isRunning,
    DateTime? startedAtUtc,
    int? accumulatedPauseSeconds,
    Duration? elapsed,
    bool? isPaused,
    List<String>? selectedMoods,
    List<GoalItem>? goals,
    String? wallpaperUrl,
    bool? hasActiveSession,
    String? title,
    String? spaceId,
    List<String>? emotionTagIds,
    int? wifiScore,
    int? noiseLevel,
    int? crowdness,
    bool? power,
  }) {
    return RecordState(
      isRunning: isRunning ?? this.isRunning,
      startedAtUtc: startedAtUtc ?? this.startedAtUtc,
      accumulatedPauseSeconds:
          accumulatedPauseSeconds ?? this.accumulatedPauseSeconds,
      elapsed: elapsed ?? this.elapsed,
      isPaused: isPaused ?? this.isPaused,
      selectedMoods: selectedMoods ?? this.selectedMoods,
      goals: goals ?? this.goals,
      wallpaperUrl: wallpaperUrl ?? this.wallpaperUrl,
      hasActiveSession: hasActiveSession ?? this.hasActiveSession,
      title: title ?? this.title,
      spaceId: spaceId ?? this.spaceId,
      emotionTagIds: emotionTagIds ?? this.emotionTagIds,
      wifiScore: wifiScore ?? this.wifiScore,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      crowdness: crowdness ?? this.crowdness,
      power: power ?? this.power,
    );
  }
}

// =====================
// Provider
// =====================
final recordControllerProvider =
    StateNotifierProvider<RecordController, RecordState>((ref) {
  final svc = ref.watch(recordServiceProvider);
  print('2️⃣ record_controller.dart: RecordController REBUILT.');
  return RecordController(ref, svc);
});

// =====================
// Controller
// =====================
class RecordController extends StateNotifier<RecordState> {
  final Ref ref;
  final dynamic _svc; // RecordService
  Timer? _ticker;
  DateTime? _pausedAtUtc;

  RecordController(this.ref, this._svc) : super(const RecordState());

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // ✅ 토큰 보장: provider → Supabase 세션 → SharedPreferences 순으로 복구
  Future<bool> _ensureToken() async {
    var tok = ref.read(authTokenProvider) ?? '';
    if (tok.isNotEmpty) return true;

    // Supabase 세션에서 복구
    try {
      final supaTok = Supabase.instance.client.auth.currentSession?.accessToken;
      if (supaTok != null && supaTok.isNotEmpty) {
        ref.read(authTokenProvider.notifier).state = supaTok;
        return true;
      }
    } catch (_) {}

    // SharedPreferences에서 복구
    try {
      final prefs = await SharedPreferences.getInstance();
      final fromPrefs = prefs.getString('access_token');
      if (fromPrefs != null && fromPrefs.isNotEmpty) {
        ref.read(authTokenProvider.notifier).state = fromPrefs;
        return true;
      }
    } catch (_) {}

    return false;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = state.startedAtUtc;
      if (start == null) return;
      final now = DateTime.now().toUtc();
      final sec = now.difference(start).inSeconds - state.accumulatedPauseSeconds;
      state = state.copyWith(elapsed: Duration(seconds: sec < 0 ? 0 : sec));
    });
  }

  // =====================
  // 시작 플로우 (토큰 가드 + 상태 복구)
  // =====================
  Future<void> startWithArgs(StartArgs args, {BuildContext? context}) async {
    // ✅ 토큰 가드
    if (!await _ensureToken()) {
      if (context != null) _showError(context, '로그인이 만료되었습니다. 다시 로그인해 주세요.');
      return;
    }

    var tok = ref.read(authTokenProvider) ?? '';
    print('🔑 startWithArgs token: ${tok.substring(0, 12)}•••');

    DateTime startedAt = DateTime.now().toUtc();
    List<GoalItem> goals = args.goals.map((e) => GoalItem(e, false)).toList();
    bool isPaused = false;

    // === 1) 기존 세션 조회
    try {
      final found = await _svc.fetchUserSession();
      final existing = _rootDataOrSelf(_asMap(found));
      if (existing.isNotEmpty) {
        final status = _mapStatus(existing['status']);

        if (status == _SessionStatus.completed) {
          // 완료 세션은 새로 시작 유도 (정리 시도 후 진행)
          try {
            await _svc.finishSession();
          } catch (_) {}
          try {
            await _svc.exportToRecord(
              title: (args.title.isNotEmpty) ? args.title : '공부 기록',
              emotionTagIds: args.emotionTagIds,
              spaceId: args.spaceId,
              wifiScore: args.wifiScore,
              noiseLevel: args.noiseLevel,
              crowdness: args.crowdness,
              power: args.power,
            );
          } catch (_) {}
          // 계속해서 새로 시작 시도
        } else if (status == _SessionStatus.paused || status == _SessionStatus.running) {
          // 활성 세션 복구
          final acc = _asInt(existing['accumulatedPauseSeconds']) ?? 0;
          startedAt = _asDateTime(existing['start_time']) ?? startedAt;
          isPaused   = (status == _SessionStatus.paused);

          goals = [];
          for (final g in _asList(existing['goals'])) {
            final gm = _asMap(g);
            final text = gm['text']?.toString();
            if (text != null) {
              goals.add(GoalItem(text, _asBool(gm['done'])));
            }
          }

          state = state.copyWith(
            startedAtUtc: startedAt,
            accumulatedPauseSeconds: acc,
            isPaused: isPaused,
            isRunning: !isPaused,
            hasActiveSession: true,
            goals: goals.isNotEmpty ? goals : state.goals,
            selectedMoods: args.moodId.isNotEmpty ? [args.moodId] : state.selectedMoods,
            // export 메타
            title: args.title,
            spaceId: args.spaceId,
            emotionTagIds: args.emotionTagIds,
            wifiScore: args.wifiScore,
            noiseLevel: args.noiseLevel,
            crowdness: args.crowdness,
            power: args.power,
          );
          if (!isPaused) _startTicker();
          if (state.selectedMoods.isNotEmpty) _fetchWallpaper(state.selectedMoods.last);
          return;
        }
      }
    } catch (e) {
      print('⚠️ 세션 조회 실패(무시하고 새로 시작): $e');
    }

    // === 2) 새 세션 시작
    Future<void> _startNew() async {
      final respRaw = await _svc.startSession(
        moodId: args.moodId, // 서비스에서 배열로 감싸도록 처리돼 있어야 함
        goals: args.goals,
      );
      final resp = _rootDataOrSelf(_asMap(respRaw));

      startedAt = _asDateTime(resp['start_time']) ?? startedAt;

      // 서버가 session/goals로 줄 수도 있음
      final session = _asMap(resp['session']);
      List<GoalItem> serverGoals = [];
      final srcGoals = session.isNotEmpty ? session['goals'] : resp['goals'];
      for (final g in _asList(srcGoals)) {
        final gm = _asMap(g);
        final text = gm['text']?.toString();
        if (text != null) serverGoals.add(GoalItem(text, _asBool(gm['done'])));
      }
      if (serverGoals.isNotEmpty) goals = serverGoals;
    }

    try {
      await _startNew();
    } catch (e) {
  final msg = e.toString().toLowerCase();
  bool recovered = false;

  // 👉 이미 세션 있음 → 기존 세션 복구
  final isAlreadyExists = (msg.contains('이미') && msg.contains('세션')) ||
                          (msg.contains('already') && msg.contains('exist'));
  if (isAlreadyExists) {
    try {
      final found = await _svc.fetchUserSession();
      final existing = _rootDataOrSelf(_asMap(found));
      if (existing.isNotEmpty) {
        final status = _mapStatus(existing['status']);
        if (status == _SessionStatus.running || status == _SessionStatus.paused) {
          final acc = _asInt(existing['accumulatedPauseSeconds']) ?? 0;
          startedAt = _asDateTime(existing['start_time']) ?? startedAt;
          isPaused  = (status == _SessionStatus.paused);

          goals = [];
          for (final g in _asList(existing['goals'])) {
            final gm = _asMap(g);
            final text = gm['text']?.toString();
            if (text != null) goals.add(GoalItem(text, _asBool(gm['done'])));
          }

          // ✅ 상태 복구
          state = state.copyWith(
            startedAtUtc: startedAt,
            accumulatedPauseSeconds: acc,
            isPaused: isPaused,
            isRunning: !isPaused,
            hasActiveSession: true,
            goals: goals.isNotEmpty ? goals : state.goals,
            // export 메타는 넘겨받은 걸 반영
            selectedMoods: args.moodId.isNotEmpty ? [args.moodId] : state.selectedMoods,
            title: args.title,
            spaceId: args.spaceId,
            emotionTagIds: args.emotionTagIds,
            wifiScore: args.wifiScore,
            noiseLevel: args.noiseLevel,
            crowdness: args.crowdness,
            power: args.power,
          );
          if (!isPaused) _startTicker();
          if (state.selectedMoods.isNotEmpty) _fetchWallpaper(state.selectedMoods.last);
          recovered = true;
        }
      }
    } catch (e2) {
      print('🚨 기존 세션 복구 실패: $e2');
    }
  }

  if (!recovered) {
    print('🚨 공부 시작 API 에러 발생: $e');
    if (context != null) _showError(context, '기존 세션 불러오기.');
    return; // 더 진행하지 않음
  } else {
    return; // 이미 복구해서 반환
  }
}
    // === 3) 상태 갱신
    final initMoods = args.moodId.isEmpty ? <String>[] : <String>[args.moodId];

    state = state.copyWith(
      startedAtUtc: startedAt,
      isRunning: !isPaused,
      hasActiveSession: true,
      isPaused: isPaused,
      selectedMoods: initMoods.isNotEmpty ? initMoods : state.selectedMoods,
      goals: goals,
      // export 메타
      title: args.title,
      spaceId: args.spaceId,
      emotionTagIds: args.emotionTagIds,
      wifiScore: args.wifiScore,
      noiseLevel: args.noiseLevel,
      crowdness: args.crowdness,
      power: args.power,
    );

    if (state.selectedMoods.isNotEmpty) _fetchWallpaper(state.selectedMoods.last);
    if (!isPaused) _startTicker();
  }

  // =====================
  // 일시정지 / 재개
  // =====================
  Future<void> pause({BuildContext? context}) async {
    if (state.isPaused) return;
    if (!state.isRunning) return;

    // ✅ 토큰 가드
    if (!await _ensureToken()) {
      if (context != null) _showError(context, '로그인이 만료되었습니다. 다시 로그인해 주세요.');
      return;
    }

    _ticker?.cancel();
    _pausedAtUtc = DateTime.now().toUtc();
    state = state.copyWith(isPaused: true, isRunning: false);

    try {
      final resp = _rootDataOrSelf(_asMap(await _svc.pauseSession()));
      final acc = _asInt(resp['accumulatedPauseSeconds']);
      if (acc != null) {
        state = state.copyWith(accumulatedPauseSeconds: acc);
      }
    } catch (e) {
      if (_isAlreadyPausedErr(e)) return; // 이미 정지면 성공 취급
      // 롤백
      state = state.copyWith(isPaused: false, isRunning: true);
      if (context != null) _showError(context, '일시정지에 실패했습니다.');
    }
  }

  Future<void> resume({BuildContext? context}) async {
    if (!state.isPaused) return;

    // ✅ 토큰 가드
    if (!await _ensureToken()) {
      if (context != null) _showError(context, '로그인이 만료되었습니다. 다시 로그인해 주세요.');
      return;
    }

    int acc = state.accumulatedPauseSeconds;
    final pausedAt = _pausedAtUtc;
    if (pausedAt != null) {
      acc += DateTime.now().toUtc().difference(pausedAt).inSeconds;
    }

    state = state.copyWith(
      isPaused: false,
      isRunning: true,
      accumulatedPauseSeconds: acc,
    );
    _pausedAtUtc = null;
    _startTicker();

    try {
      final resp = _rootDataOrSelf(_asMap(await _svc.resumeSession()));
      final acc2 = _asInt(resp['accumulatedPauseSeconds']);
      if (acc2 != null) {
        state = state.copyWith(accumulatedPauseSeconds: acc2);
      }
    } catch (e) {
      if (_isAlreadyRunningErr(e)) return; // 이미 실행 중이면 성공 취급
      // 롤백
      _ticker?.cancel();
      _pausedAtUtc = DateTime.now().toUtc();
      state = state.copyWith(isPaused: true, isRunning: false);
      if (context != null) _showError(context, '다시 시작에 실패했습니다.');
    }
  }

  // =====================
  // 종료 / 내보내기
  // =====================
  Future<Map<String, dynamic>> finish({BuildContext? context}) async {
    // ✅ 토큰 가드
    if (!await _ensureToken()) {
      if (context != null) _showError(context, '로그인이 만료되었습니다. 다시 로그인해 주세요.');
      // 로컬 타이머 정리는 해 줌
      _ticker?.cancel();
      _pausedAtUtc = null;
      state = state.copyWith(isRunning: false, isPaused: false);
      throw Exception('토큰 없음으로 finish 호출 불가');
    }

    try {
      return await _svc.finishSession();
    } finally {
      _ticker?.cancel();
      _pausedAtUtc = null;
      state = state.copyWith(
        isRunning: false,
        isPaused: false,
      );
    }
  }

  Future<Map<String, dynamic>> exportToRecord() {
  // Google Place ID 같은 정상 ID만 허용(대충 ChI… 또는 길이/문자셋)
  bool _looksValidSpaceId(String? s) {
    if (s == null || s.trim().isEmpty) return false;
    final v = s.trim();
    if (v.startsWith('ChI')) return true;                // 구글 Place ID 패턴 흔함
    if (RegExp(r'^[A-Za-z0-9_\-]{12,}$').hasMatch(v)) {  // 임의 ID일 수도
      return true;
    }
    return false;
  }

  final safeSpaceId = _looksValidSpaceId(state.spaceId) ? state.spaceId : null;

  return _svc.exportToRecord(
    title: state.title,
    emotionTagIds: state.emotionTagIds,
    spaceId: safeSpaceId,          // 🔑 잘못된 값은 null로 전달(서버에서 생략 처리)
    wifiScore: state.wifiScore,
    noiseLevel: state.noiseLevel,
    crowdness: state.crowdness,
    power: state.power,
  );
}

  // =====================
  // 목표
  // =====================
  Future<void> addGoal(String text, {bool done = false, BuildContext? context}) async {
    // ✅ 토큰 가드
    if (!await _ensureToken()) {
      if (context != null) _showError(context, '로그인이 만료되었습니다. 다시 로그인해 주세요.');
      return;
    }

    final prev = state.goals;
    final optimistic = [...prev, GoalItem(text, done)];
    state = state.copyWith(goals: optimistic);

    try {
      final resp = _rootDataOrSelf(_asMap(await _svc.addGoal(text, done: done)));
      final list = _asList(resp['goals']);
      state = state.copyWith(
        goals: list.map((g) {
          final m = _asMap(g);
          return GoalItem(m['text']?.toString() ?? '', _asBool(m['done']));
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(goals: prev);
      if (context != null) _showError(context, '목표 추가에 실패했습니다.');
    }
  }

  Future<void> toggleGoal(int index, bool done, {BuildContext? context}) async {
    // ✅ 토큰 가드
    if (!await _ensureToken()) {
      if (context != null) _showError(context, '로그인이 만료되었습니다. 다시 로그인해 주세요.');
      return;
    }

    final prev = state.goals;
    if (index < 0 || index >= prev.length) return;

    final next = [...prev];
    next[index] = prev[index].copyWith(done: done);
    state = state.copyWith(goals: next);

    try {
      final resp = _rootDataOrSelf(_asMap(await _svc.toggleGoal(index, done)));
      final list = _asList(resp['goals']);
      state = state.copyWith(
        goals: list.map((g) {
          final m = _asMap(g);
          return GoalItem(m['text']?.toString() ?? '', _asBool(m['done']));
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(goals: prev);
      if (context != null) {
        final msg = e.toString();
        if (msg.contains('완료된 세션')) {
          _showError(context, '완료된 세션은 목표를 수정할 수 없습니다.');
        } else {
          _showError(context, '목표 상태 변경에 실패했습니다.');
        }
      }
    }
  }

  /// Finalize(기록 Step2) 입력 값들을 state에 반영하는 메서드
  void applyFinalizeMeta({
    String? title,
    List<String>? emotionTagIds,
    String? spaceId,
    int? wifiScore,
    int? noiseLevel,
    int? crowdness,
    bool? power,
  }) {
    state = state.copyWith(
      title: title ?? state.title,
      emotionTagIds: emotionTagIds ?? state.emotionTagIds,
      spaceId: spaceId ?? state.spaceId,
      wifiScore: wifiScore ?? state.wifiScore,
      noiseLevel: noiseLevel ?? state.noiseLevel,
      crowdness: crowdness ?? state.crowdness,
      power: power ?? state.power,
    );
  }

  Future<void> removeGoal(int index, {BuildContext? context}) async {
    // 필요 시 구현
  }

  // =====================
  // 무드 & 배경
  // =====================
  Future<void> toggleMood(String mood) async {
    final list = [...state.selectedMoods];
    if (list.contains(mood)) {
      list.remove(mood);
    } else {
      list.add(mood);
    }
    state = state.copyWith(selectedMoods: list);

    if (list.isNotEmpty) {
      await _fetchWallpaper(list.last);
    } else {
      state = state.copyWith(wallpaperUrl: '');
    }
  }

  Future<void> _fetchWallpaper(String mood) async {
    try {
      final url = await _svc.fetchWallpaper(mood);
      state = state.copyWith(wallpaperUrl: url);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

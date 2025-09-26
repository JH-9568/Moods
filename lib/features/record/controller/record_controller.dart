// lib/features/record/controller/record_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  if (s == 'paused') return _SessionStatus.paused;
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
    while (norm.length % 4 != 0) {
      norm += '=';
    }
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
  return (s.contains('이미') && (s.contains('일시') || s.contains('pause'))) ||
      (s.contains('already') && (s.contains('paused') || s.contains('pause')));
}

bool _isAlreadyRunningErr(Object e) {
  final s = e.toString().toLowerCase();
  return (s.contains('이미') && (s.contains('재개') || s.contains('resume'))) ||
      (s.contains('already') && (s.contains('running') || s.contains('resum')));
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
  final String? activeRecordId; // 서버가 준 record_id

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
    this.activeRecordId,
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
    String? activeRecordId,
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
      activeRecordId: activeRecordId ?? this.activeRecordId,
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
  bool _starting = false; // 🔒 start 재진입 가드
  Timer? _moodDebounce;

  RecordController(this.ref, this._svc) : super(const RecordState());

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _primeFinalizeState(Map<String, dynamic> existing) {
    final durSec = _asInt(existing['duration']) ?? 0;
    final recId = existing['record_id']?.toString();
    final goals = <GoalItem>[];
    for (final g in _asList(existing['goals'])) {
      final gm = _asMap(g);
      final text = gm['text']?.toString();
      if (text != null) goals.add(GoalItem(text, _asBool(gm['done'])));
    }
    final moods = _asList(
      existing['mood_id'],
    ).map((e) => e.toString()).toList();

    state = state.copyWith(
      elapsed: Duration(seconds: durSec),
      goals: goals,
      selectedMoods: moods,
      activeRecordId: recId,
      // ✅ “활성 세션”은 run/pause에만 true. completed는 false로 둔다.
      hasActiveSession: false,
      isRunning: false,
      isPaused: false,
    );
  }

  // ✅ 토큰 보장: provider → Supabase 세션 → SharedPreferences 순으로 복구
  Future<bool> _ensureToken() async {
    var tok = ref.read(authTokenProvider) ?? '';
    if (tok.isNotEmpty) return true;

    try {
      final supaTok = Supabase.instance.client.auth.currentSession?.accessToken;
      if (supaTok != null && supaTok.isNotEmpty) {
        ref.read(authTokenProvider.notifier).state = supaTok;
        return true;
      }
    } catch (_) {}

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
      final sec =
          now.difference(start).inSeconds - state.accumulatedPauseSeconds;
      state = state.copyWith(elapsed: Duration(seconds: sec < 0 ? 0 : sec));
    });
  }

  // ---------- 공용: 세션 파싱 + 상태 반영 ----------
  void _applyRecoveredSession(
    Map<String, dynamic> existing, {
    required StartArgs args,
  }) {
    final status = _mapStatus(existing['status']);
    final acc = _asInt(existing['accumulatedPauseSeconds']) ?? 0;
    final startedAt =
        _asDateTime(existing['start_time']) ?? DateTime.now().toUtc();
    final recId = existing['record_id']?.toString();
    final moods = _asList(
      existing['mood_id'],
    ).map((e) => e.toString()).toList();

    final goals = <GoalItem>[];
    for (final g in _asList(existing['goals'])) {
      final gm = _asMap(g);
      final text = gm['text']?.toString();
      if (text != null) goals.add(GoalItem(text, _asBool(gm['done'])));
    }

    final isPaused = (status == _SessionStatus.paused);
    final isRunning = (status == _SessionStatus.running);

    state = state.copyWith(
      activeRecordId: recId,
      startedAtUtc: startedAt,
      accumulatedPauseSeconds: acc,
      isPaused: isPaused,
      isRunning: isRunning,
      hasActiveSession: isPaused || isRunning,
      goals: goals.isNotEmpty ? goals : state.goals,
      selectedMoods: args.moodId.isNotEmpty
          ? [args.moodId]
          : (moods.isNotEmpty ? moods : state.selectedMoods),
      // finalize 메타 유지/갱신
      title: args.title,
      spaceId: args.spaceId,
      emotionTagIds: args.emotionTagIds,
      wifiScore: args.wifiScore,
      noiseLevel: args.noiseLevel,
      crowdness: args.crowdness,
      power: args.power,
    );

    if (isRunning)
      _startTicker();
    else
      _ticker?.cancel();
    if (state.selectedMoods.isNotEmpty)
      _fetchWallpaper(state.selectedMoods.last);
  }

  // 🩹 finished 세션이면 export → finish → “정리완료”로 간주하도록 보조 루틴
  Future<void> _exportAndFinishIfNeeded(
    StartArgs args,
    Map<String, dynamic> existing,
  ) async {
    final st = _mapStatus(existing['status']);
    if (st != _SessionStatus.completed) return;

    // spaceId 안전 검사 (exportToRecord의 검사와 동일 로직)
    bool _looksValidSpaceId(String? s) {
      if (s == null || s.trim().isEmpty) return false;
      final v = s.trim();
      if (v.startsWith('ChI')) return true;
      if (RegExp(r'^[A-Za-z0-9_\\-]{12,}$').hasMatch(v)) return true;
      return false;
    }

    final safeSpaceId = _looksValidSpaceId(args.spaceId) ? args.spaceId : null;

    try {
      await _svc.exportToRecord(
        title: args.title,
        emotionTagIds: args.emotionTagIds,
        spaceId: safeSpaceId,
        wifiScore: args.wifiScore,
        noiseLevel: args.noiseLevel,
        crowdness: args.crowdness,
        power: args.power,
      );
    } catch (_) {
      // export 실패해도 진행은 계속(백엔드 정책에 따라 필요 시만)
    }

    try {
      await _svc.finishSession();
    } catch (_) {}
  }

  static const _kUnexportedErr = 'unexported_session_exists';

Future<void> startWithArgs(StartArgs args, {BuildContext? context}) async {
  if (_starting) return;
  _starting = true;
  try {
    if (!await _ensureToken()) {
      if (context != null) _showError(context, '로그인이 만료되었습니다. 다시 로그인해 주세요.');
      return;
    }

    // ---------- 1) 선조회 ----------
    Map<String, dynamic> existing = {};
    try {
      final found = await _svc.fetchUserSession();
      existing = _rootDataOrSelf(_asMap(found));
    } catch (e) {
      // 조회 실패는 새 시작 시도 쪽으로 넘김
      print('⚠️ 사전 조회 실패(무시): $e');
    }

    if (existing.isNotEmpty) {
      final status = _mapStatus(existing['status']);
      if (status == _SessionStatus.running || status == _SessionStatus.paused) {
        print('↩️ 기존 활성 세션 복구');
        _applyRecoveredSession(existing, args: args);
        return;
      }
      if (status == _SessionStatus.completed) {
        print('ℹ️ 완료 세션 발견 → 기록하기로 보냄');
        _primeFinalizeState(existing);
        throw Exception(_kUnexportedErr);
      }
    }

    // ---------- 2) 새 세션 시작 ----------
    DateTime startedAt = DateTime.now().toUtc();
    List<GoalItem> goals = args.goals.map((e) => GoalItem(e, false)).toList();

    Future<void> _startNew() async {
      final respRaw = await _svc.startSession(
        moodId: args.moodId,
        goals: args.goals,
      );
      final resp = _rootDataOrSelf(_asMap(respRaw));

      startedAt = _asDateTime(resp['start_time']) ?? startedAt;
      final session = _asMap(resp['session']);
      final srcGoals = session.isNotEmpty ? session['goals'] : resp['goals'];
      final serverGoals = <GoalItem>[];
      for (final g in _asList(srcGoals)) {
        final gm = _asMap(g);
        final text = gm['text']?.toString();
        if (text != null) serverGoals.add(GoalItem(text, _asBool(gm['done'])));
      }
      if (serverGoals.isNotEmpty) goals = serverGoals;

      final recId = (session['record_id'] ?? resp['record_id'])?.toString();
      if (recId != null && recId.isNotEmpty) {
        state = state.copyWith(activeRecordId: recId);
      }
    }

    try {
      await _startNew();
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final already =
          (msg.contains('이미') && msg.contains('세션')) ||
          (msg.contains('already') && msg.contains('exist'));

      if (!already) {
        print('🚨 세션 시작 실패: $e');
        if (context != null) _showError(context, '세션 시작 실패');
        return;
      }

      // ---------- 3) “이미 있음”이면 재조회 한 번으로 분기 ----------
        try {
          Map<String, dynamic> again = {};

          // 1차 조회
          final found = await _svc.fetchUserSession();
          again = _rootDataOrSelf(_asMap(found));

          // 비어있으면 아주 짧게 기다렸다가 1회 재시도 (쓰기-읽기 지연 방지)
          if (again.isEmpty) {
            await Future.delayed(const Duration(milliseconds: 150));
            final found2 = await _svc.fetchUserSession();
            again = _rootDataOrSelf(_asMap(found2));
          }

          if (again.isNotEmpty) {
            final st = _mapStatus(again['status']);

            if (st == _SessionStatus.running || st == _SessionStatus.paused) {
              print('재조회로 활성 세션 복구');
              _applyRecoveredSession(again, args: args);
              return;
            }

            if (st == _SessionStatus.completed) {
              print('재조회 완료 세션 → 기록하기로 보냄');
              _primeFinalizeState(again);
              throw Exception(_kUnexportedErr);
            }
          }

          // 여기까지 왔으면 진짜 없음
          print('“이미 있음”인데 재조회 결과 없음/알 수 없음');
          if (context != null) _showError(context, '세션 이어하기');
          return;
        } catch (e2) {
          print('“이미 있음” 재조회 실패: $e2');
          if (context != null) _showError(context, '세션 시작 실패');
          return;
        }
    }

    // ---------- 4) 새 세션 시작 성공 상태 반영 ----------
    final initMoods = args.moodId.isEmpty ? <String>[] : <String>[args.moodId];
    state = state.copyWith(
      startedAtUtc: startedAt,
      isRunning: true,
      isPaused: false,
      hasActiveSession: true, // run/pause일 때만 true
      selectedMoods: initMoods.isNotEmpty ? initMoods : state.selectedMoods,
      goals: goals,
      title: args.title,
      spaceId: args.spaceId,
      emotionTagIds: args.emotionTagIds,
      wifiScore: args.wifiScore,
      noiseLevel: args.noiseLevel,
      crowdness: args.crowdness,
      power: args.power,
    );

    if (state.selectedMoods.isNotEmpty) _fetchWallpaper(state.selectedMoods.last);
    _startTicker();

  } catch (e) {
    _starting = false;
    rethrow; // UI에서 unexported_session_exists 처리
  } finally {
    if (_starting) _starting = false;
  }
}
 Future<bool> quit({BuildContext? context}) async {
    if (!await _ensureToken()) {
      if (context != null) _showError(context, '로그인이 만료되었습니다. 다시 로그인해 주세요.');
      return false;
    }
    try {
      await _svc.quitSession(); // RecordService.quitSession()
      // 로컬 상태 정리
      _ticker?.cancel();
      _pausedAtUtc = null;
      state = const RecordState();
      return true;
    } catch (e) {
      if (context != null) _showError(context, '세션 종료에 실패했습니다.');
      return false;
    }
  }

  // =====================
  // 일시정지 / 재개
  // =====================
  Future<void> pause({BuildContext? context}) async {
    if (state.isPaused) return;
    if (!state.isRunning) return;

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
      if (_isAlreadyPausedErr(e)) return;
      state = state.copyWith(isPaused: false, isRunning: true);
      if (context != null) _showError(context, '일시정지에 실패했습니다.');
    }
  }

  Future<void> resume({BuildContext? context}) async {
    if (!state.isPaused) return;

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
      if (_isAlreadyRunningErr(e)) return;
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
    if (!await _ensureToken()) {
      if (context != null) _showError(context, '로그인이 만료되었습니다. 다시 로그인해 주세요.');
      _ticker?.cancel();
      _pausedAtUtc = null;
      state = state.copyWith(isRunning: false, isPaused: false);
      throw Exception('토큰 없음으로 finish 호출 불가');
    }

    try {
      final raw = await _svc.finishSession();
      final resp = _asMap(raw);
      final data = _rootDataOrSelf(resp);

      final recId = (data['record_id'] ?? resp['record_id'])?.toString();

      state = state.copyWith(
        isRunning: false,
        isPaused: false,
        hasActiveSession: false,
        activeRecordId: recId ?? state.activeRecordId,
      );
      return resp;
    } finally {
      _ticker?.cancel();
      _pausedAtUtc = null;
    }
  }

  Future<Map<String, dynamic>> exportToRecord() {
    bool _looksValidSpaceId(String? s) {
      if (s == null || s.trim().isEmpty) return false;
      final v = s.trim();
      if (v.startsWith('ChI')) return true;
      if (RegExp(r'^[A-Za-z0-9_\-]{12,}$').hasMatch(v)) return true;
      return false;
    }

    final safeSpaceId = _looksValidSpaceId(state.spaceId)
        ? state.spaceId
        : null;

    return _svc.exportToRecord(
      title: state.title,
      emotionTagIds: state.emotionTagIds,
      spaceId: safeSpaceId,
      wifiScore: state.wifiScore,
      noiseLevel: state.noiseLevel,
      crowdness: state.crowdness,
      power: state.power,
    );
  }

  // =====================
  // 목표
  // =====================
  Future<void> addGoal(
    String text, {
    bool done = false,
    BuildContext? context,
  }) async {
    if (!await _ensureToken()) {
      if (context != null) _showError(context, '로그인이 만료되었습니다. 다시 로그인해 주세요.');
      return;
    }

    final prev = state.goals;
    final optimistic = [...prev, GoalItem(text, done)];
    state = state.copyWith(goals: optimistic);

    try {
      final resp = _rootDataOrSelf(
        _asMap(await _svc.addGoal(text, done: done)),
      );
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

  // 중복/공백 제거(순서 유지)
  List<String> _normalizeMoods(List<String> input) {
    final out = <String>[];
    for (final m in input) {
      final s = m.toString().trim();
      if (s.isEmpty) continue;
      if (!out.contains(s)) out.add(s);
    }
    return out;
  }

  // 서버 PATCH(/study-sessions/mood)를 300ms 디바운스로 호출
  void _scheduleMoodPatch() {
    _moodDebounce?.cancel();
    _moodDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!await _ensureToken()) return;
      final moods = _normalizeMoods(state.selectedMoods);
      try {
        final resp = await _svc.updateSessionMood(
          moods,
        ); // ← RecordService에 추가됨
        final serverMoods = (resp['mood_id'] is List)
            ? (resp['mood_id'] as List).map((e) => e.toString()).toList()
            : moods;
        state = state.copyWith(selectedMoods: serverMoods);
        print('✅ mood synced: $serverMoods');
      } catch (e) {
        print('⚠️ mood patch failed: $e'); // 실패해도 UI는 유지
      }
    });
  }

  Future<void> toggleMood(String mood) async {
    // 1) 로컬 낙관적 갱신
    final list = [...state.selectedMoods];
    if (list.contains(mood)) {
      list.remove(mood);
    } else {
      list.add(mood);
    }
    final normalized = _normalizeMoods(list);
    state = state.copyWith(selectedMoods: normalized);

    // 2) 배경 갱신
    if (normalized.isNotEmpty) {
      await _fetchWallpaper(mood);
    } else {
      state = state.copyWith(wallpaperUrl: '');
    }

    // 3) 서버 동기화 (디바운스)
    _scheduleMoodPatch();
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
    _moodDebounce?.cancel(); // ← 추가: 디바운서 정리
    super.dispose();
  }
}

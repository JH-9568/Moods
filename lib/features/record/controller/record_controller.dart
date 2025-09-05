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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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
      final sec = now.difference(start).inSeconds - state.accumulatedPauseSeconds;
      state = state.copyWith(elapsed: Duration(seconds: sec < 0 ? 0 : sec));
    });
  }

  // ---------- 공용: 세션 파싱 + 상태 반영 ----------
  void _applyRecoveredSession(Map<String, dynamic> existing, {
    required StartArgs args,
  }) {
    final status = _mapStatus(existing['status']);
    final acc = _asInt(existing['accumulatedPauseSeconds']) ?? 0;
    final startedAt = _asDateTime(existing['start_time']) ?? DateTime.now().toUtc();
    final recId = existing['record_id']?.toString();
    final moods = _asList(existing['mood_id']).map((e) => e.toString()).toList();

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

    if (isRunning) _startTicker(); else _ticker?.cancel();
    if (state.selectedMoods.isNotEmpty) _fetchWallpaper(state.selectedMoods.last);
  }

  // 🩹 finished 세션이면 export → finish → “정리완료”로 간주하도록 보조 루틴
  Future<void> _exportAndFinishIfNeeded(StartArgs args, Map<String, dynamic> existing) async {
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

    try { await _svc.finishSession(); } catch (_) {}
  }

  // ---------- finish 이후 세션 확인: finished면 OK로 간주(비어있지 않아도 진행) ----------
   Future<void> _waitClearAfterFinish({int attempts = 12, int baseDelayMs = 200}) async {
    for (int i = 0; i < attempts; i++) {
      try {
        final found = await _svc.fetchUserSession();
        final existing = _rootDataOrSelf(_asMap(found)); // 404/null → {}
        if (existing.isEmpty) {
          print('✅ finish 후 세션 비어짐 (try=${i + 1})');
          return; // 세션이 완전히 비워졌을 때만 성공으로 간주하고 종료
        }
        
        // 'completed' 상태를 더 이상 성공으로 간주하지 않음
        final st = _mapStatus(existing['status']);
        print('⏳ finish 후 아직 세션 데이터 남아있음 (status=$st) (try=${i + 1})');

      } catch (e) {
        // 404 Not Found 같은 예외가 발생하면 세션이 없는 것으로 간주하고 성공 처리할 수도 있습니다.
        // 예: if (e.toString().contains('404')) { print('✅ 404 응답, 정리된 것으로 간주'); return; }
        print('🟠 finish 후 확인 실패 (try=${i + 1}): $e');
      }
      await Future.delayed(Duration(milliseconds: baseDelayMs * (i + 1)));
    }
    print('⌛ finish 후 확인 타임아웃 — 그래도 진행');
  }
  Future<bool> _pollAndRecoverExisting(StartArgs args,
      {int attempts = 15, int baseDelayMs = 200}) async {
    for (int i = 0; i < attempts; i++) {
      try {
        final found = await _svc.fetchUserSession();
        final existing = _rootDataOrSelf(_asMap(found));
        if (existing.isNotEmpty) {
          final status = _mapStatus(existing['status']);
          if (status == _SessionStatus.running || status == _SessionStatus.paused) {
            print('🟢 폴링복구 성공 (try=${i + 1})');
            _applyRecoveredSession(existing, args: args);
            return true;
          } else if (status == _SessionStatus.completed) {
            print('ℹ️ 폴링 중 completed 감지');
          }
        } else {
          print('🟡 폴링 (try=${i + 1}) 아직 비어있음');
        }
      } catch (e) {
        print('🟠 폴링 실패 (try=${i + 1}): $e');
      }
      await Future.delayed(Duration(milliseconds: baseDelayMs * (i + 1)));
    }
    return false;
  }
Future<void> startWithArgs(StartArgs args, {BuildContext? context}) async {
    if (_starting) return;
    _starting = true;
    try {
      if (!await _ensureToken()) {
        if (context != null) _showError(context, '로그인이 만료되었습니다. 다시 로그인해 주세요.');
        return;
      }

      final tok = ref.read(authTokenProvider) ?? '';
      final preview = tok.length > 12 ? tok.substring(0, 12) : tok;
      print('🔑 startWithArgs token: $preview•••');

      // 1) 먼저 조회해서 있으면 바로 복구 / completed면 에러 발생
      try {
        final found = await _svc.fetchUserSession();
        final existing = _rootDataOrSelf(_asMap(found));
        if (existing.isNotEmpty) {
          final status = _mapStatus(existing['status']);
          if (status == _SessionStatus.completed) {
          // 1. 이전 세션 데이터를 파싱해서 상태에 먼저 적용합니다.
          final durSec = _asInt(existing['duration']) ?? 0;
          final goals = <GoalItem>[];
          for (final g in _asList(existing['goals'])) {
            final gm = _asMap(g);
            final text = gm['text']?.toString();
            if (text != null) goals.add(GoalItem(text, _asBool(gm['done'])));
          }
          final moods = _asList(existing['mood_id']).map((e) => e.toString()).toList();
          final recId = existing['record_id']?.toString();

          state = state.copyWith(
            elapsed: Duration(seconds: durSec),
            goals: goals,
            selectedMoods: moods,
            activeRecordId: recId,
            hasActiveSession: true, // 기록 완료를 위해 활성 세션으로 간주
          );
          print('ℹ️ 미정리 세션 데이터 로드 완료. 시간: ${state.elapsed}');

          // 2. 그 다음에 에러를 던져서 화면을 이동시킵니다.
          throw Exception('unexported_session_exists');
        } else if (status == _SessionStatus.running || status == _SessionStatus.paused) {
            print('↩️ 기존 활성 세션 즉시 복구');
            _applyRecoveredSession(existing, args: args);
            return; // 복구 성공 시 함수 종료
          }
        }
      } catch (e) {
        // UI에서 처리해야 하는 'unexported_session_exists' 예외는 다시 던져줍니다.
        if (e.toString().contains('unexported_session_exists')) {
          rethrow;
        }
        // 그 외의 일반적인 조회 실패(e.g. 네트워크 오류)는 무시하고 새 세션 만들기로 진행합니다.
        print('⚠️ 사전 조회 실패(무시): $e');
      }

      // ==========================================================
      // ▼ 아래부터는 기존의 '새 세션 시작' 로직입니다.
      // ==========================================================
      DateTime startedAt = DateTime.now().toUtc();
      List<GoalItem> goals = args.goals.map((e) => GoalItem(e, false)).toList();
      bool isPaused = false;

      // 2) 새 세션 시작 시도
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
        final isAlreadyExists =
            (msg.contains('이미') && msg.contains('세션')) ||
            (msg.contains('already') && msg.contains('exist'));

        if (isAlreadyExists) {
          print('⚓ 이미 세션 존재 응답 → 폴링 복구 시도');
          final ok = await _pollAndRecoverExisting(args, attempts: 15, baseDelayMs: 200);
          if (!ok) {
            print('🧹 폴링 실패 → export(가능시) → finish → 짧은 대기 → 재시작');
            try {
              final found = await _svc.fetchUserSession();
              final existing = _rootDataOrSelf(_asMap(found));
              await _exportAndFinishIfNeeded(args, existing);
            } catch (_) {}
            try { await _svc.finishSession(); } catch (_) {}
            await _waitClearAfterFinish();

            try {
              await _startNew();
            } catch (e2) {
              print('🚨 재시작도 폭망: $e2');
              if (context != null) _showError(context, '세션 시작 실패');
              return;
            }
          } else {
            return;
          }
        } else {
          print('🚨 공부 시작 API 에러: $e');
          if (context != null) _showError(context, '세션 시작 실패');
          return;
        }
      }

      // 3) 상태 갱신 (새 시작 성공 루트)
      final initMoods = args.moodId.isEmpty ? <String>[] : <String>[args.moodId];
      state = state.copyWith(
        startedAtUtc: startedAt,
        isRunning: !isPaused,
        hasActiveSession: true,
        isPaused: isPaused,
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
      if (!isPaused) _startTicker();

    } catch(e) {
      // rethrow된 예외를 여기서 최종적으로 잡아서 UI로 전달합니다.
      _starting = false; 
      rethrow;
    } finally {
      // 정상적으로 함수가 끝나거나, return으로 중간에 빠져나갈 때
      // _starting 플래그를 false로 설정합니다.
      if (_starting) _starting = false;
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

    final safeSpaceId = _looksValidSpaceId(state.spaceId) ? state.spaceId : null;

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
  Future<void> addGoal(String text, {bool done = false, BuildContext? context}) async {
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
        final resp = await _svc.updateSessionMood(moods); // ← RecordService에 추가됨
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

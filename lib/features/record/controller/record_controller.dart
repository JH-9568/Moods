// lib/features/record/controller/record_controller.dart
import 'dart:async';
import 'package:flutter/material.dart'; // ScaffoldMessenger 때문에 추가
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/providers.dart'; // recordServiceProvider가 있는 파일

// ==== StartArgs ====
// UI에서 Controller로 초기 데이터를 넘기기 위한 클래스 (기존과 동일)
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

// export를 위해 필요한 정보들을 상태에 저장하도록 필드 추가
class RecordState {
  // 타이머 관련 상태
  final bool isRunning;
  final DateTime? startedAtUtc;
  final int accumulatedPauseSeconds;
  final Duration elapsed;
  final bool isPaused;

  // 세션 정보
  final List<String> selectedMoods;
  final List<GoalItem> goals;
  final String wallpaperUrl;
  final bool hasActiveSession;
  
  // exportToRecord에 필요한 정보 (추가된 필드)
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
    // 추가된 필드 초기화
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

final recordControllerProvider =
    StateNotifierProvider<RecordController, RecordState>((ref) {
  final svc = ref.watch(recordServiceProvider);
  print('2️⃣ record_controller.dart: RecordController REBUILT.');
  return RecordController(svc);
});

class RecordController extends StateNotifier<RecordState> {
  final dynamic _svc; // RecordService
  Timer? _ticker;
  DateTime? _pausedAtUtc;

  RecordController(this._svc) : super(const RecordState());

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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

  Future<void> startWithArgs(StartArgs args, {BuildContext? context}) async {
  DateTime startedAt = DateTime.now().toUtc();
  List<GoalItem> goals = args.goals.map((e) => GoalItem(e, false)).toList();

  try {
    // Postman 기준에 맞춰 moodId와 goals만 전달합니다.
    final resp = await _svc.startSession(
      moodId: args.moodId,
      goals: args.goals,
    );
    final iso = (resp['start_time'] as String?) ??
        DateTime.now().toUtc().toIso8601String();
    startedAt = DateTime.parse(iso).toUtc();

    final session = resp['session'] as Map<String, dynamic>?;
    final serverGoals =
        (session?['goals'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (serverGoals.isNotEmpty) {
      goals = serverGoals
          .map((g) => GoalItem(g['text'] as String, (g['done'] as bool?) ?? false))
          .toList();
    }
  } catch (e) {
    // =======================================================
    // ✅ 1. 진짜 에러 원인을 콘솔에 출력하는 코드 (가장 중요!)
    print('🚨 공부 시작 API 에러 발생: $e');
    // =======================================================
    
    if (context != null) _showError(context, '공부 시작에 실패했습니다.');
  }


    final initMoods = args.moodId.isEmpty ? <String>[] : <String>[args.moodId];

    state = state.copyWith(
      startedAtUtc: startedAt,
      isRunning: true,
      hasActiveSession: true,
      isPaused: false,
      selectedMoods: initMoods,
      goals: goals,
      // export를 위해 초기 정보를 state에 저장
      title: args.title,
      spaceId: args.spaceId,
      emotionTagIds: args.emotionTagIds,
      wifiScore: args.wifiScore,
      noiseLevel: args.noiseLevel,
      crowdness: args.crowdness,
      power: args.power,
    );

    if (initMoods.isNotEmpty) {
      _fetchWallpaper(initMoods.last);
    }
    _startTicker();
  }

  Future<void> pause({BuildContext? context}) async {
    _ticker?.cancel();
    _pausedAtUtc = DateTime.now().toUtc();
    state = state.copyWith(isPaused: true, isRunning: false);

    try {
      final resp = await _svc.pauseSession();
      final acc = (resp['accumulatedPauseSeconds'] as num?)?.toInt();
      if (acc != null) state = state.copyWith(accumulatedPauseSeconds: acc);
    } catch (e) {
      if (context != null) _showError(context, '일시정지에 실패했습니다.');
    }
  }

  Future<void> resume({BuildContext? context}) async {
    int acc = state.accumulatedPauseSeconds;
    final pausedAt = _pausedAtUtc;
    if (pausedAt != null) {
      acc += DateTime.now().toUtc().difference(pausedAt).inSeconds;
    }
    state = state.copyWith(isPaused: false, isRunning: true, accumulatedPauseSeconds: acc);
    _pausedAtUtc = null;
    _startTicker();

    try {
      final resp = await _svc.resumeSession();
      final acc2 = (resp['accumulatedPauseSeconds'] as num?)?.toInt();
      if (acc2 != null) state = state.copyWith(accumulatedPauseSeconds: acc2);
    } catch (e) {
      if (context != null) _showError(context, '다시 시작에 실패했습니다.');
    }
  }

  Future<Map<String, dynamic>> finish() async {
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
    return _svc.exportToRecord(
      title: state.title,
      emotionTagIds: state.emotionTagIds,
      spaceId: state.spaceId,
      wifiScore: state.wifiScore,
      noiseLevel: state.noiseLevel,
      crowdness: state.crowdness,
      power: state.power,
    );
  }
  
  Future<void> addGoal(String text, {bool done = false, BuildContext? context}) async {
    final prev = state.goals;
    final optimistic = [...prev, GoalItem(text, done)];
    state = state.copyWith(goals: optimistic);

    try {
      final resp = await _svc.addGoal(text, done: done);
      final list = (resp['goals'] as List).cast<Map<String, dynamic>>();
      state = state.copyWith(
        goals: list.map((g) => GoalItem(g['text'] as String, g['done'] as bool)).toList(),
      );
    } catch (e) {
      state = state.copyWith(goals: prev);
      if (context != null) _showError(context, '목표 추가에 실패했습니다.');
    }
  }

Future<void> toggleGoal(int index, bool done, {BuildContext? context}) async {
  // 1. UI 즉시 변경 (낙관적 업데이트)
  final prev = state.goals;
  if (index < 0 || index >= prev.length) return;
  final next = [...prev];
  next[index] = prev[index].copyWith(done: done);
  state = state.copyWith(goals: next);

  try {
    // 2. 서버에 요청
    final resp = await _svc.toggleGoal(index, done);

    // =======================================================
    // ✅ 서버가 보내준 응답 전체를 출력해서 확인!
    print('✅ toggleGoal API 응답: $resp');
    // =======================================================

    // 3. 서버 응답으로 덮어쓰기
    final list = (resp['goals'] as List).cast<Map<String, dynamic>>();
    state = state.copyWith(
      goals: list.map((g) => GoalItem(g['text'] as String, g['done'] as bool)).toList(),
    );
  } catch (e) {
    // 4. 실패 시 롤백 및 에러 출력
    print('🚨 toggleGoal API 에러: $e');
    state = state.copyWith(goals: prev);
    if (context != null) _showError(context, '목표 상태 변경에 실패했습니다.');
  }
}

  Future<void> removeGoal(int index, {BuildContext? context}) async {
    // ... (removeGoal 구현 시 에러 처리 추가)
  }

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
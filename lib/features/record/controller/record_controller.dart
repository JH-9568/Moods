// lib/features/record/controller/record_controller.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/providers.dart'; // recordServiceProvider

class StartArgs {
  final String mood;
  final List<String> goals;
  final String title;
  final String spaceId;
  final String emotion;
  final List<String> spaceFeature;
  const StartArgs({
    required this.mood,
    required this.goals,
    required this.title,
    required this.spaceId,
    required this.emotion,
    required this.spaceFeature,
  });
}

class GoalItem {
  final String text;
  final bool done;
  const GoalItem(this.text, this.done);
}

class RecordState {
  final bool isRunning;
  final DateTime? startedAtUtc;
  final int accumulatedPauseSeconds;
  final Duration elapsed;
  final String selectedMood;
  final List<GoalItem> goals;
  final String wallpaperUrl;
  final bool hasActiveSession;
  final bool isPaused;
  final bool dirty;

  const RecordState({
    this.isRunning = false,
    this.startedAtUtc,
    this.accumulatedPauseSeconds = 0,
    this.elapsed = Duration.zero,
    this.selectedMood = '',
    this.goals = const [],
    this.wallpaperUrl = '',
    this.hasActiveSession = false,
    this.isPaused = false,
    this.dirty = false,
  });

  RecordState copyWith({
    bool? isRunning,
    DateTime? startedAtUtc,
    int? accumulatedPauseSeconds,
    Duration? elapsed,
    String? selectedMood,
    List<GoalItem>? goals,
    String? wallpaperUrl,
    bool? hasActiveSession,
    bool? isPaused,
    bool? dirty,
  }) {
    return RecordState(
      isRunning: isRunning ?? this.isRunning,
      startedAtUtc: startedAtUtc ?? this.startedAtUtc,
      accumulatedPauseSeconds: accumulatedPauseSeconds ?? this.accumulatedPauseSeconds,
      elapsed: elapsed ?? this.elapsed,
      selectedMood: selectedMood ?? this.selectedMood,
      goals: goals ?? this.goals,
      wallpaperUrl: wallpaperUrl ?? this.wallpaperUrl,
      hasActiveSession: hasActiveSession ?? this.hasActiveSession,
      isPaused: isPaused ?? this.isPaused,
      dirty: dirty ?? this.dirty,
    );
  }
}

final recordControllerProvider = StateNotifierProvider<RecordController, RecordState>((ref) {
  final svc = ref.watch(recordServiceProvider);
  return RecordController(svc);
});

class RecordController extends StateNotifier<RecordState> {
  final dynamic _svc; // RecordService
  Timer? _ticker;

  RecordController(this._svc) : super(const RecordState());

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = state.startedAtUtc;
      if (start == null) return;
      final now = DateTime.now().toUtc();
      final elapsedSec = now.difference(start).inSeconds - state.accumulatedPauseSeconds;
      state = state.copyWith(elapsed: Duration(seconds: elapsedSec < 0 ? 0 : elapsedSec));
    });
  }

  Future<void> startWithArgs(StartArgs args) async {
    final resp = await _svc.startSession(
      mood: args.mood,
      goals: args.goals,
      title: args.title,
      spaceId: args.spaceId,
      emotion: args.emotion,
      spaceFeature: args.spaceFeature,
    );

    final startIso = (resp['start_time'] as String?) ?? DateTime.now().toUtc().toIso8601String();
    final startedAt = DateTime.parse(startIso).toUtc();

    final session = resp['session'] as Map<String, dynamic>?;
    final serverGoals = (session?['goals'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final goals = serverGoals.isNotEmpty
        ? serverGoals.map((g) => GoalItem(g['text'] as String, (g['done'] as bool?) ?? false)).toList()
        : args.goals.map((e) => GoalItem(e, false)).toList();

    state = state.copyWith(
      startedAtUtc: startedAt,
      isRunning: true,
      hasActiveSession: true,
      isPaused: false,
      selectedMood: args.mood,
      goals: goals,
      dirty: true,
    );

    try {
      final url = await _svc.fetchWallpaper(args.mood);
      state = state.copyWith(wallpaperUrl: url);
    } catch (_) {}

    _startTicker();
  }

  Future<void> pause() async {
    final resp = await _svc.pauseSession();
    final acc = (resp['accumulatedPauseSeconds'] as num?)?.toInt() ?? state.accumulatedPauseSeconds;
    state = state.copyWith(isPaused: true, isRunning: false, accumulatedPauseSeconds: acc);
    _ticker?.cancel();
  }

  Future<void> resume() async {
    final resp = await _svc.resumeSession();
    final acc = (resp['accumulatedPauseSeconds'] as num?)?.toInt() ?? state.accumulatedPauseSeconds;
    state = state.copyWith(isPaused: false, isRunning: true, accumulatedPauseSeconds: acc);
    _startTicker();
  }

  Future<Map<String, dynamic>> finish() async {
    final resp = await _svc.finishSession();
    state = state.copyWith(isRunning: false, hasActiveSession: false, isPaused: false, dirty: false);
    _ticker?.cancel();
    return resp;
  }

  Future<Map<String, dynamic>> exportToRecord() => _svc.exportToRecord();

  // ===== Goals =====

  // 목표 추가
  Future<void> addGoal(String text, {bool done = false}) async {
    final resp = await _svc.addGoal(text, done: done);
    final goalsJson = (resp['goals'] as List).cast<Map<String, dynamic>>();
    final updated = goalsJson
        .map((g) => GoalItem(g['text'] as String, (g['done'] as bool)))
        .toList();
    state = state.copyWith(goals: updated);
  }

  // 목표 토글
  Future<void> toggleGoal(int index, bool done) async {
    final resp = await _svc.toggleGoal(index, done);
    final goalsJson = (resp['goals'] as List).cast<Map<String, dynamic>>();
    final updated = goalsJson
        .map((g) => GoalItem(g['text'] as String, (g['done'] as bool)))
        .toList();
    state = state.copyWith(goals: updated);
  }

  // 목표 제거
  Future<void> removeGoal(int index) async {
    final resp = await _svc.removeGoal(index);
    final goalsJson = (resp['goals'] as List).cast<Map<String, dynamic>>();
    final updated = goalsJson
        .map((g) => GoalItem(g['text'] as String, (g['done'] as bool)))
        .toList();
    state = state.copyWith(goals: updated);
  }

  Future<void> selectMood(String mood) async {
    state = state.copyWith(selectedMood: mood);
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

// lib/features/home/widget/study_time/study_time_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/home/widget/study_time/study_time_service.dart';
import 'package:moods/providers.dart';

enum StudyScope { month, week }

class StudyTimeState {
  final bool loading;
  final bool loadedOnce;
  final String? error;

  final StudyScope scope;
  final Duration month; // 이번 달
  final Duration week; // 이번 주

  const StudyTimeState({
    this.loading = false,
    this.loadedOnce = false,
    this.error,
    this.scope = StudyScope.month,
    this.month = Duration.zero,
    this.week = Duration.zero,
  });

  Duration get current => scope == StudyScope.month ? month : week;

  StudyTimeState copyWith({
    bool? loading,
    bool? loadedOnce,
    String? error, // null을 넣으면 에러를 지움
    StudyScope? scope,
    Duration? month,
    Duration? week,
  }) {
    return StudyTimeState(
      loading: loading ?? this.loading,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      error: error,
      scope: scope ?? this.scope,
      month: month ?? this.month,
      week: week ?? this.week,
    );
  }
}

class StudyTimeController extends StateNotifier<StudyTimeState> {
  final StudyTimeService service;
  StudyTimeController({required this.service}) : super(const StudyTimeState());

  Future<void> loadIfNeeded() async {
    if (state.loading || state.loadedOnce) return;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final monthDur = await service.fetchThisMonthDuration();
      final weekDur = await service.fetchThisWeekDuration();

      print(
        '[StudyTimeController] fetched durations -> '
        'month=${_fmt(monthDur)}, week=${_fmt(weekDur)}',
      );

      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        month: monthDur,
        week: weekDur,
        error: null,
      );

      print(
        '[StudyTimeController] state applied. '
        'scope=${state.scope}, current=${_fmt(state.current)}',
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        error: e.toString(),
      );
      print('[StudyTimeController] error: $e');
    }
  }

  void setScope(StudyScope s) {
    if (s == state.scope) return;
    state = state.copyWith(scope: s);
    print(
      '[StudyTimeController] setScope -> $s (current=${_fmt(state.current)})',
    );
  }

  String _fmt(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:'
      '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
      '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

final studyTimeControllerProvider =
    StateNotifierProvider<StudyTimeController, StudyTimeState>((ref) {
      final svc = ref.read(studyTimeServiceProvider);
      return StudyTimeController(service: svc);
    });

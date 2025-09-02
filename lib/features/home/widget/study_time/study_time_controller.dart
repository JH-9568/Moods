// 역할: 이번 달/이번 주 토글 상태 및 로딩/에러/누적시간을 관리 (Riverpod StateNotifier)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/providers.dart'; // authTokenProvider 사용 (네가 준 providers.dart)
import 'package:moods/features/home/widget/study_time/study_time_service.dart';

/// 화면 상단 세그먼트 값
enum StudyTotalRange { month, week }

/// UI가 바로 쓰기 좋은 상태(단순·명확)
class StudyTimeState {
  final StudyTotalRange range; // 현재 선택
  final Duration total;        // 누적 시간
  final bool loading;          // 로딩 플래그
  final String? error;         // 에러 메시지

  const StudyTimeState({
    required this.range,
    required this.total,
    required this.loading,
    this.error,
  });

  factory StudyTimeState.initial() =>
      const StudyTimeState(range: StudyTotalRange.month, total: Duration.zero, loading: true);

  StudyTimeState copyWith({
    StudyTotalRange? range,
    Duration? total,
    bool? loading,
    String? error, // null을 명시적으로 세팅할 수 있게
  }) {
    return StudyTimeState(
      range: range ?? this.range,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// Service 주입 (Auth 토큰 연동)
///
/// 핵심: jwtProvider 클로저가 매 호출때마다 최신 토큰을 읽어 Authorization 헤더에 반영
final studyTimeServiceProvider = Provider<StudyTimeService>((ref) {
  return StudyTimeService(
    jwtProvider: () {
      final t = ref.read(authTokenProvider);
      return (t == null || t.isEmpty) ? '' : 'Bearer $t';
    },
  );
});

/// Controller + 상태 Provider
final studyTimeControllerProvider =
    StateNotifierProvider<StudyTimeController, StudyTimeState>((ref) {
  final service = ref.read(studyTimeServiceProvider);
  return StudyTimeController(service: service)..load(); // 최초 진입 시 이번 달 로드
});

class StudyTimeController extends StateNotifier<StudyTimeState> {
  final StudyTimeService service;

  StudyTimeController({required this.service}) : super(StudyTimeState.initial());

  /// 현재 range 기준으로 로드
  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final minutes = await _fetchByRange(state.range);
      state = state.copyWith(
        loading: false,
        total: Duration(minutes: minutes),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        total: Duration.zero,
        error: e.toString(),
      );
    }
  }

  /// 범위 변경 (세그먼트 탭 전환)
  Future<void> setRange(StudyTotalRange range) async {
    if (state.range == range && !state.loading) {
      // 필요하면 강제 새로고침: await load();
      state = state.copyWith(range: range); // UI 즉시 반영
      return;
    }
    state = state.copyWith(range: range);
    await load();
  }

  /// 수동 새로고침
  Future<void> refresh() => load();

  Future<int> _fetchByRange(StudyTotalRange range) {
    switch (range) {
      case StudyTotalRange.month:
        return service.fetchThisMonthTotalMinutes();
      case StudyTotalRange.week:
        return service.fetchThisWeekTotalMinutes();
    }
  }
}
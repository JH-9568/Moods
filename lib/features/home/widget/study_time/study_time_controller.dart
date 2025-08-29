// lib/features/home/widget/study_time/study_time_controller.dart
// 역할: 범위 변경 및 데이터 로딩 로직을 관리하는 StateNotifier

/* 	studyTimeControllerProvider : 화면에서 구독할 상태/액션.
	•	load() : 현재 범위 기준으로 통계 호출.
	•	setRange() : 범위 바꾸고 다시 로드.
  
   */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/home/widget/study_time/study_time_provider.dart';
import 'package:moods/features/home/widget/study_time/study_time_service.dart';

final studyTimeControllerProvider =
    StateNotifierProvider<StudyTimeController, StudyTimeState>((ref) {
  final service = ref.read(studyTimeServiceProvider);
  return StudyTimeController(service: service)..load(); // 초기 로드(이번 달)
});

class StudyTimeController extends StateNotifier<StudyTimeState> {
  final StudyTimeService service;

  StudyTimeController({required this.service}) : super(StudyTimeState.initial());

  /// 초기 및 갱신 로드
  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final minutes = await _fetchByRange(state.range);
      state = state.copyWith(total: Duration(minutes: minutes), loading: false, error: null);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString(), total: Duration.zero);
    }
  }

  /// 범위 변경(세그먼트 탭) → 재조회
  Future<void> setRange(StudyTotalRange range) async {
    if (state.range == range && !state.loading) {
      // 동일 선택이면 무시 가능 (원한다면 강제 새로고침하려면 load() 호출)
    }
    state = state.copyWith(range: range);
    await load();
  }

  Future<int> _fetchByRange(StudyTotalRange range) {
    switch (range) {
      case StudyTotalRange.month:
        return service.fetchThisMonthTotalMinutes();
      case StudyTotalRange.week:
        return service.fetchThisWeekTotalMinutes();
    }
  }
}
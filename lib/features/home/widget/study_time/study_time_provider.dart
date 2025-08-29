// lib/features/home/widget/study_time/study_time_provider.dart
// 역할: enum/상태/Provider 정의 (Riverpod)

/*
	•	StudyTotalRange : 세그먼트 선택 값
	•	StudyTimeState : 현재 범위/총시간/로딩/오류
	•	studyJwtProvider : JWT를 주입할 수 있는 지점(없으면 빈 문자열).
	•	studyTimeServiceProvider : Service 인스턴스 제공.
*/

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/home/widget/study_time/study_time_service.dart';

/// 화면 상단 세그먼트의 범위
enum StudyTotalRange { month, week }

/// 화면에 필요한 상태(단순/명확)
class StudyTimeState {
  final StudyTotalRange range; // 현재 선택: 이번 달 / 이번 주
  final Duration total;        // 누적 시간
  final bool loading;          // 로딩 여부
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
    String? error, // null 자체를 설정하고 싶을 때는 명시적으로 전달
  }) {
    return StudyTimeState(
      range: range ?? this.range,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// JWT 주입 Provider (없으면 빈 토큰). 실제 앱에서 ProviderScope.override로 교체 가능.
final studyJwtProvider = Provider<JwtProvider>((ref) {
  return () => ''; // 기본은 빈 문자열. 필요 시 'Bearer xxx'로 오버라이드하세요.
});

/// Service Provider
final studyTimeServiceProvider = Provider<StudyTimeService>((ref) {
  final jwtGetter = ref.read(studyJwtProvider);
  return StudyTimeService(jwtProvider: jwtGetter);
});
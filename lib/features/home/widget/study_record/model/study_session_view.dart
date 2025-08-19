class StudySessionView {
  final String id;               // 임시/실제 공통 식별자
  final String title;            // 주제/요약
  final String locationName;     // 위치명 (없으면 "위치 없음" 등으로 처리)
  final DateTime startAtLocal;   // 로컬(KST) 기준 시작 시각
  final DateTime? endAtLocal;    // 종료 전이면 null
  final int? durationMinutes;    // 종료 전이면 null
  final bool isOptimistic;       // 백엔드 확정 전 임시 표시 여부

  const StudySessionView({
    required this.id,
    required this.title,
    required this.locationName,
    required this.startAtLocal,
    this.endAtLocal,
    this.durationMinutes,
    this.isOptimistic = false,
  });
}
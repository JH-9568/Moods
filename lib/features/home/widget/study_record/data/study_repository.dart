// lib/data/repositories/study_repository.dart
import 'package:moods/features/home/widget/study_record/model/study_session_view.dart';

/// 화면/상태에서 데이터 접근에 쓰는 "약속(계약)"입니다.
/// 구현체는 Mock 또는 Supabase로 교체 가능합니다.
abstract class StudyRepository {
  /// 최근 기록을 페이지 단위로 가져옵니다.
  /// - [cursor]: 마지막으로 받은 아이템의 id (없으면 처음부터)
  /// - [limit]: 한 번에 가져올 개수
  /// - return: 화면용 DTO(StudySessionView) 목록
  Future<List<StudySessionView>> fetchRecent({String? cursor, int limit = 20});

  /// 공부를 "시작"했을 때, 화면에 즉시 보여줄 임시 카드를 만듭니다.
  /// - return: isOptimistic=true 인 StudySessionView
  Future<StudySessionView> startSession({
    required String topic,
    String? locationId,
  });

  /// 진행 중인 세션을 "종료"하여 확정 데이터로 갱신합니다.
  /// - return: 서버 기준으로 확정된 StudySessionView
  Future<StudySessionView> endSession({required String sessionId});
}
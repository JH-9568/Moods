import 'dart:async';
import 'package:moods/features/home/widget/study_record/model/study_session_view.dart';
import 'package:moods/features/home/widget/study_record/data/study_repository.dart';

class MockStudyRepository implements StudyRepository {
  final List<StudySessionView> _data = List.generate(
    16,
        (i) => StudySessionView(
      id: 'mock-$i',
      title: ['운영체제','알고리즘','자료구조','수학'][i % 4],
      locationName: ['도서관','카페','집'][i % 3],
      startAtLocal: DateTime.now().subtract(Duration(hours: i * 5 + 1)),
      endAtLocal: DateTime.now().subtract(Duration(hours: i * 5)),
      durationMinutes: 60 + (i % 3) * 30,
    ),
  );

  @override
  Future<List<StudySessionView>> fetchRecent({String? cursor, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // 아주 단순한 커서 흉내: cursor가 null이면 0부터, 아니면 cursor 다음부터
    int start = 0;
    if (cursor != null) {
      final idx = _data.indexWhere((e) => e.id == cursor);
      start = (idx >= 0) ? idx + 1 : 0;
    }
    final end = (start + limit > _data.length) ? _data.length : start + limit;
    return _data.sublist(start, end);
  }

  @override
  Future<StudySessionView> startSession({required String topic, String? locationId}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return StudySessionView(
      id: 'optimistic-${DateTime.now().microsecondsSinceEpoch}',
      title: topic,
      locationName: '도서관',
      startAtLocal: DateTime.now(),
      endAtLocal: null,
      durationMinutes: null,
      isOptimistic: true,
    );
  }

  @override
  Future<StudySessionView> endSession({required String sessionId}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return StudySessionView(
      id: sessionId,
      title: '업데이트됨',
      locationName: '도서관',
      startAtLocal: DateTime.now().subtract(const Duration(hours: 2)),
      endAtLocal: DateTime.now(),
      durationMinutes: 120,
    );
  }
}
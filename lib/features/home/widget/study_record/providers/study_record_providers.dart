import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/home/widget/study_record/data/mock_study_repository.dart';
import 'package:moods/features/home/widget/study_record/data/study_repository.dart';
import 'package:moods/features/home/widget/study_record/model/study_session_view.dart';

/// 나중에 Supabase로 교체할 때 이 provider만 override 하면 됩니다.
final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  return MockStudyRepository();
});

class StudyRecordState {
  final AsyncValue<List<StudySessionView>> list; // 로딩/에러/데이터
  final bool isLoadingMore;
  final String? lastCursor; // 마지막 아이템 id 기반 커서

  const StudyRecordState({
    required this.list,
    this.isLoadingMore = false,
    this.lastCursor,
  });

  StudyRecordState copyWith({
    AsyncValue<List<StudySessionView>>? list,
    bool? isLoadingMore,
    String? lastCursor,
  }) {
    return StudyRecordState(
      list: list ?? this.list,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastCursor: lastCursor ?? this.lastCursor,
    );
  }

  static const empty = StudyRecordState(list: AsyncValue.data([]));
}

class StudyRecordController extends StateNotifier<StudyRecordState> {
  final StudyRepository repo;
  StudyRecordController(this.repo)
      : super(const StudyRecordState(list: AsyncValue.loading()));

  Future<void> loadInitial() async {
    state = state.copyWith(list: const AsyncValue.loading(), lastCursor: null);
    try {
      final data = await repo.fetchRecent(limit: 12);
      state = state.copyWith(
        list: AsyncValue.data(data),
        lastCursor: data.isNotEmpty ? data.last.id : null,
      );
    } catch (e, st) {
      state = state.copyWith(list: AsyncValue.error(e, st));
    }
  }

  Future<void> refresh() async => loadInitial();

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;
    final current = state.list.value ?? [];
    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await repo.fetchRecent(cursor: state.lastCursor, limit: 10);
      final merged = [...current, if (more.isNotEmpty) ...more];
      state = state.copyWith(
        list: AsyncValue.data(merged),
        isLoadingMore: false,
        lastCursor: more.isNotEmpty ? more.last.id : state.lastCursor,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> startOptimistic(String topic) async {
    final optimistic = await repo.startSession(topic: topic);
    final current = state.list.value ?? [];
    state = state.copyWith(list: AsyncValue.data([optimistic, ...current]));
    // 실제 Supabase 붙이면: 서버 응답으로 optimistic 치환 로직 추가
  }
}

final studyRecordProvider =
StateNotifierProvider<StudyRecordController, StudyRecordState>((ref) {
  final repo = ref.watch(studyRepositoryProvider);
  return StudyRecordController(repo);
});
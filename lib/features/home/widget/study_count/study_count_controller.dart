// lib/features/home/widget/study_count/study_count_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/home/widget/study_count/study_count_service.dart';
import 'package:moods/providers.dart';

class StudyCountState {
  final bool loading;
  final bool loadedOnce;
  final String? error;
  // API 응답과 맞추기 위해 필드명을 totalCount로 고정
  final int totalCount;

  const StudyCountState({
    this.loading = false,
    this.loadedOnce = false,
    this.error,
    this.totalCount = 0,
  });

  StudyCountState copyWith({
    bool? loading,
    bool? loadedOnce,
    String? error,
    int? totalCount,
  }) {
    return StudyCountState(
      loading: loading ?? this.loading,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      error: error,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class StudyCountController extends StateNotifier<StudyCountState> {
  final StudyCountService service;
  StudyCountController({required this.service})
    : super(const StudyCountState());

  Future<void> loadIfNeeded() async {
    if (state.loading || state.loadedOnce) return;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final total = await service.fetchTotalSessions();

      // 로그
      // ignore: avoid_print
      print('[StudyCountController] fetched totalCount=$total');

      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        totalCount: total,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        error: e.toString(),
      );
    }
  }
}

/// Provider
final studyCountControllerProvider =
    StateNotifierProvider<StudyCountController, StudyCountState>((ref) {
      final svc = ref.read(studyCountServiceProvider);
      return StudyCountController(service: svc);
    });

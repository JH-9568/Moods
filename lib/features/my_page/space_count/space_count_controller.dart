// lib/features/home/widget/my_page/study_space_count_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/my_page/space_count/space_count_service.dart';
import 'package:moods/providers.dart';

class StudySpaceCountState {
  final bool loading;
  final bool loadedOnce;
  final String? error;
  final int totalSpaces;

  const StudySpaceCountState({
    this.loading = false,
    this.loadedOnce = false,
    this.error,
    this.totalSpaces = 0,
  });

  StudySpaceCountState copyWith({
    bool? loading,
    bool? loadedOnce,
    String? error,
    int? totalSpaces,
  }) {
    return StudySpaceCountState(
      loading: loading ?? this.loading,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      error: error,
      totalSpaces: totalSpaces ?? this.totalSpaces,
    );
  }
}

class StudySpaceCountController extends StateNotifier<StudySpaceCountState> {
  final StudySpaceCountService service;

  StudySpaceCountController({required this.service})
    : super(const StudySpaceCountState());

  Future<void> loadIfNeeded() async {
    if (state.loading || state.loadedOnce) return;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final count = await service.fetchTotalSpaces();
      print('[StudySpaceCountController] fetched totalSpaces=$count');

      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        totalSpaces: count,
        error: null,
      );
      print(
        '[StudySpaceCountController] state applied. totalSpaces=${state.totalSpaces}',
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

/// 위젯에서 watch/read 할 프로바이더
final studySpaceCountControllerProvider =
    StateNotifierProvider<StudySpaceCountController, StudySpaceCountState>((
      ref,
    ) {
      final svc = ref.read(studySpaceCountServiceProvider);
      return StudySpaceCountController(service: svc);
    });

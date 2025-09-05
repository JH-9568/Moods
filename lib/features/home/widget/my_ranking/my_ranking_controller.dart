// lib/features/home/widget/my_ranking/my_ranking_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'my_ranking_service.dart'; // MySpaceRank, myRankingServiceProvider

/// 화면 상태
class MyRankingState {
  final bool loading;
  final bool loadedOnce;
  final String? error;
  final List<MySpaceRank> items; // <-- 여기 타입을 MySpaceRank로

  const MyRankingState({
    this.loading = false,
    this.loadedOnce = false,
    this.error,
    this.items = const [],
  });

  MyRankingState copyWith({
    bool? loading,
    bool? loadedOnce,
    String? error,
    List<MySpaceRank>? items, // <-- 동일하게 맞춰주기
  }) {
    return MyRankingState(
      loading: loading ?? this.loading,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      error: error,
      items: items ?? this.items,
    );
  }
}

/// 비즈니스 로직
class MyRankingController extends StateNotifier<MyRankingState> {
  final MyRankingService service;

  MyRankingController({required this.service}) : super(const MyRankingState());

  Future<void> loadIfNeeded() async {
    if (state.loading || state.loadedOnce) return;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await service.fetchMySpacesRanks(); // List<MySpaceRank>
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        items: items, // <-- 타입 일치
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

/// provider
final myRankingControllerProvider =
    StateNotifierProvider<MyRankingController, MyRankingState>(
      (ref) {
        final svc = ref.watch(myRankingServiceProvider);
        return MyRankingController(service: svc);
      },
      dependencies: [myRankingServiceProvider], // ← 추가
    );

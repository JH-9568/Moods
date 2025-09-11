// lib/features/home/widget/my_ranking/my_ranking_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_service.dart';
import 'package:moods/providers.dart';

class MyRankingState {
  final bool loading;
  final bool loadedOnce;
  final String? error;
  final List<MySpaceRank> items;

  const MyRankingState({
    this.loading = false,
    this.loadedOnce = false,
    this.error,
    this.items = const [],
  });

  MyRankingState copyWith({
    bool? loading,
    bool? loadedOnce,
    String? error, // null 대입으로 클리어
    List<MySpaceRank>? items,
  }) {
    return MyRankingState(
      loading: loading ?? this.loading,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      error: error,
      items: items ?? this.items,
    );
  }
}

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
      final list = await service.fetchMySpacesRanks();
      final top5 = list.take(5).toList(growable: false);

      print(
        '[MyRankingController] fetched count=${list.length} (top5=${top5.length}'
        '${top5.isNotEmpty ? ', first=${top5.first.spaceName}' : ''})',
      );

      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        items: top5,
        error: null,
      );
      print('[MyRankingController] state applied. items=${state.items.length}');
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
final myRankingControllerProvider =
    StateNotifierProvider<MyRankingController, MyRankingState>((ref) {
      final svc = ref.read(myRankingServiceProvider);
      return MyRankingController(service: svc);
    });

// lib/features/home/widget/home_record/home_record_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/home/widget/study_record/home_record_service.dart';
import 'package:moods/providers.dart'; // homeRecordServiceProvider 읽기용

class HomeRecordState {
  final bool loading;
  final bool loadedOnce;
  final String? error;
  final List<RecentSpace> items;

  const HomeRecordState({
    this.loading = false,
    this.loadedOnce = false,
    this.error,
    this.items = const [],
  });

  HomeRecordState copyWith({
    bool? loading,
    bool? loadedOnce,
    String? error, // null 대입으로 에러 클리어
    List<RecentSpace>? items,
  }) {
    return HomeRecordState(
      loading: loading ?? this.loading,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      error: error,
      items: items ?? this.items,
    );
  }
}

class HomeRecordController extends StateNotifier<HomeRecordState> {
  final HomeRecordService service;
  HomeRecordController({required this.service})
    : super(const HomeRecordState());

  Future<void> loadIfNeeded() async {
    if (state.loading || state.loadedOnce) return;
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final list = await service.fetchRecentSpaces();
      print(
        '[HomeRecordController] fetched count=${list.length}'
        '${list.isNotEmpty ? ', first=${list.first.spaceName}' : ''}',
      );
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        items: list,
        error: null,
      );
      print(
        '[HomeRecordController] state applied. items=${state.items.length}',
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
final homeRecordControllerProvider =
    StateNotifierProvider<HomeRecordController, HomeRecordState>((ref) {
      final svc = ref.read(homeRecordServiceProvider);
      return HomeRecordController(service: svc);
    });

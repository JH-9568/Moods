import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prefer_keyword_service.dart';

@immutable
class PreferKeywordState {
  final bool loading;
  final bool loadedOnce;
  final String? error;
  final List<PreferKeyword> types;
  final List<PreferKeyword> moods;
  final List<PreferKeyword> features;

  const PreferKeywordState({
    this.loading = false,
    this.loadedOnce = false,
    this.error,
    this.types = const [],
    this.moods = const [],
    this.features = const [],
  });

  PreferKeywordState copyWith({
    bool? loading,
    bool? loadedOnce,
    String? error,
    List<PreferKeyword>? types,
    List<PreferKeyword>? moods,
    List<PreferKeyword>? features,
  }) {
    return PreferKeywordState(
      loading: loading ?? this.loading,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      error: error,
      types: types ?? this.types,
      moods: moods ?? this.moods,
      features: features ?? this.features,
    );
  }

  PreferKeywordState clearError() => copyWith(error: null);
}

class PreferKeywordController extends StateNotifier<PreferKeywordState> {
  final PreferKeywordService service;
  PreferKeywordController({required this.service})
    : super(const PreferKeywordState());

  Future<void> loadIfNeeded() async {
    if (state.loading || state.loadedOnce) return;
    await refresh();
  }

  Future<void> refresh() async {
    // 이미 로딩 중이면 중복 호출 방지
    if (state.loading) return;

    state = state.clearError().copyWith(loading: true);

    try {
      final bundle = await service.fetchAll();
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        error: null,
        types: bundle.types,
        moods: bundle.moods,
        features: bundle.features,
      );
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[PreferKeywordController] refresh failed: $e');
        // ignore: avoid_print
        print(st);
      }
      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        error: e.toString(),
      );
    }
  }
}

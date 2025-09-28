// lib/features/calendar/calendar_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/calendar/calendar_service.dart'; // ← CalendarService / CalendarDayBucket 정의

/// 화면 상태
class CalendarState {
  final bool loading; // 로딩 중?
  final bool loadedOnce; // 최소 1회 로드 성공했는지
  final String? error; // 에러 메시지(없으면 null)
  final List<CalendarDayBucket> items; // 서비스에서 내려준 일자별 카드 버킷

  const CalendarState({
    required this.loading,
    required this.loadedOnce,
    required this.error,
    required this.items,
  });

  factory CalendarState.initial() => const CalendarState(
    loading: false,
    loadedOnce: false,
    error: null,
    items: <CalendarDayBucket>[],
  );

  CalendarState copyWith({
    bool? loading,
    bool? loadedOnce,
    String? error, // null을 그대로 주면 유지, 빈 문자열 주면 에러 해제하고싶을땐 ''
    List<CalendarDayBucket>? items,
  }) {
    return CalendarState(
      loading: loading ?? this.loading,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      error: error == null ? this.error : (error.isEmpty ? null : error),
      items: items ?? this.items,
    );
  }
}

/// 캘린더 컨트롤러
class CalendarController extends StateNotifier<CalendarState> {
  final CalendarService service;

  /// ✅ 해결 A: named parameter `service`
  CalendarController({required this.service}) : super(CalendarState.initial());

  /// 첫 진입 때만 로드
  Future<void> loadIfNeeded() async {
    if (state.loading || state.loadedOnce) return;
    await load();
  }

  /// 강제 새로고침
  Future<void> refresh() => load();

  /// 실제 로드
  Future<void> load() async {
    try {
      state = state.copyWith(loading: true, error: '', items: null);
      print('[CalendarController] load() start');

      final data = await service.fetchRecentVisits();
      print('[CalendarController] fetched ${data.length} buckets');

      state = state.copyWith(
        loading: false,
        loadedOnce: true,
        error: '',
        items: data,
      );
      print('[CalendarController] load() success');
    } catch (e, st) {
      print('[CalendarController] load() error: $e\n$st');
      state = state.copyWith(
        loading: false,
        loadedOnce: state.loadedOnce, // 이전 성공 여부는 유지
        error: e.toString(),
      );
    }
  }
}

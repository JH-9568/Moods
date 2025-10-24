// lib/features/calendar/calendar_controller.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/calendar/calendar_service.dart';

/// ===== Model =====
class CalendarRecord {
  final String recordId;
  final DateTime date;
  final String title;
  final int durationSeconds;
  final String spaceName;
  final Map<String, dynamic> raw;

  const CalendarRecord({
    required this.recordId,
    required this.date,
    required this.title,
    required this.durationSeconds,
    required this.spaceName,
    required this.raw,
  });
}

/// ===== Safe parsers =====
int _asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _asString(dynamic v) => v?.toString() ?? '';

DateTime _asDateLocal(dynamic v) {
  try {
    return DateTime.parse(v.toString()).toLocal();
  } catch (_) {
    return DateTime.now();
  }
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  if (v is String) {
    try {
      final d = jsonDecode(v);
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
  }
  return <String, dynamic>{};
}

/// 매핑
CalendarRecord mapToCalendarRecord(Map<String, dynamic> m) {
  final rec = _asMap(m['record'] ?? m);

  final recordId = _asString(rec['record_id'] ?? rec['id']);
  final title = _asString(rec['title'] ?? '공부 기록');

  final dateStr =
      rec['date'] ??
      rec['end_time'] ??
      rec['created_at'] ??
      DateTime.now().toIso8601String();
  final date = _asDateLocal(dateStr);

  int seconds = 0;
  final rawDur =
      rec['duration'] ??
      rec['total_seconds'] ??
      rec['net_seconds'] ??
      rec['total_time'] ??
      rec['net_time'];
  if (rawDur is num) seconds = rawDur.round();
  if (rawDur is String) seconds = (double.tryParse(rawDur) ?? 0).round();

  final space = _asMap(rec['space']);
  final spaceName = _asString(space['name'] ?? rec['space_name'] ?? '');

  return CalendarRecord(
    recordId: recordId,
    date: date,
    title: title.isNotEmpty ? title : '공부 기록',
    durationSeconds: seconds,
    spaceName: spaceName,
    raw: rec,
  );
}

/// ===== State =====
class CalendarState {
  final DateTime month; // 기준 월(1일)
  final bool loading;
  final List<CalendarRecord> records;
  final String? error;

  const CalendarState({
    required this.month,
    this.loading = false,
    this.records = const [],
    this.error,
  });

  CalendarState copyWith({
    DateTime? month,
    bool? loading,
    List<CalendarRecord>? records,
    String? error,
  }) {
    return CalendarState(
      month: month ?? this.month,
      loading: loading ?? this.loading,
      records: records ?? this.records,
      error: error,
    );
  }
}

/// ===== Controller (Provider는 providers.dart에서만 정의!) =====
class CalendarController extends StateNotifier<CalendarState> {
  final Ref ref;
  final CalendarService _svc;

  bool _fetching = false;
  DateTime? _requestedMonth;
  DateTime? _inFlightMonth;

  CalendarController(this.ref, this._svc, {required DateTime initialMonth})
    : super(CalendarState(month: initialMonth));

  /// ✅ 표시 규칙
  /// - 1시간 이상  → "H시간 M분" (초 제외)
  /// - 1분 이상   → "M분 S초"   (시간 제외)
  /// - 1분 미만   → "S초"
  String formatHHMM(int seconds) {
    final total = seconds < 0 ? 0 : seconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;

    if (h >= 1) {
      return m > 0 ? '${h}시간 ${m}분' : '${h}시간';
    } else if (m >= 1) {
      return s > 0 ? '${m}분 ${s}초' : '${m}분';
    } else {
      return '${s}초';
    }
  }

  Future<void> changeMonth(DateTime month) async {
    final first = DateTime(month.year, month.month, 1);
    if (state.month.year == first.year && state.month.month == first.month)
      return;

    state = state.copyWith(month: first);
    _requestedMonth = first;

    if (!_fetching) {
      await _fetchLatest();
    }
  }

  Future<void> fetchMonth() async {
    _requestedMonth = state.month;
    if (!_fetching) {
      await _fetchLatest();
    }
  }

  Future<void> _fetchLatest() async {
    if (_requestedMonth == null) return;
    if (_fetching && _inFlightMonth == _requestedMonth) return;

    final target = _requestedMonth!;
    _inFlightMonth = target;
    _fetching = true;
    state = state.copyWith(loading: true, error: null);

    try {
      final from = target;
      final to = DateTime(
        from.year,
        from.month + 1,
        1,
      ).subtract(const Duration(seconds: 1));
      final list = await _svc.fetchCalendarRange(from: from, to: to);

      final records = list.map(mapToCalendarRecord).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      state = state.copyWith(loading: false, records: records);
    } catch (e, st) {
      debugPrint('[Calendar][ERROR] $e');
      debugPrintStack(stackTrace: st);
      state = state.copyWith(loading: false, error: e.toString());
    } finally {
      _fetching = false;
      if (_requestedMonth != _inFlightMonth) {
        await _fetchLatest();
      } else {
        _inFlightMonth = null;
      }
    }
  }

  List<CalendarRecord> recordsOfDay(DateTime day) {
    final y = day.year, m = day.month, d = day.day;
    return state.records
        .where((r) => r.date.year == y && r.date.month == m && r.date.day == d)
        .toList();
  }

  int totalSecondsOfMonth() {
    var sum = 0;
    for (final r in state.records) {
      sum += (r.durationSeconds > 0 ? r.durationSeconds : 0);
    }
    return sum;
  }
}

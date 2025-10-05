// lib/features/calendar/calendar_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/calendar/widget/calendar_day_cell.dart';
import 'package:moods/features/calendar/dropdown/calendar_header.dart'
    show CalendarHeader, YearMonth;

// 모델은 컨트롤러 파일에서, 프로바이더는 providers.dart에서 가져오기
import 'package:moods/features/calendar/calendar_controller.dart'
    show CalendarRecord;
import 'package:moods/providers.dart'
    show calendarControllerProvider, authTokenProvider;

import 'package:moods/features/record/view/record_card_preview.dart';

const bool _verboseCalendarUILog = false;

class CalendarWidget extends ConsumerStatefulWidget {
  const CalendarWidget({super.key});
  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  YearMonth _ym = YearMonth.now();
  static const double _cellWidth = 52;
  static const double _cellHeight = 108;

  ProviderSubscription<String?>? _tokenSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authTokenProvider);
      if (token != null && token.isNotEmpty) {
        ref.read(calendarControllerProvider.notifier).fetchMonth();
        return;
      }
      _tokenSub = ref.listenManual<String?>(authTokenProvider, (prev, next) {
        if (next != null && next.isNotEmpty) {
          ref.read(calendarControllerProvider.notifier).fetchMonth();
          _tokenSub?.close();
          _tokenSub = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _tokenSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(calendarControllerProvider.notifier);

    // records만 구독 → 리빌드 최소화
    final records = ref.watch(
      calendarControllerProvider.select((s) => s.records),
    );

    final monthRecords = records.where(
      (r) => r.date.year == _ym.year && r.date.month == _ym.month,
    );

    if (_verboseCalendarUILog && kDebugMode) {
      debugPrint(
        '[CalendarWidget] yearMonth=$_ym  monthRecords=${monthRecords.length}',
      );
    }

    final Map<int, List<CalendarRecord>> dayMap = {};
    for (final r in monthRecords) {
      dayMap.putIfAbsent(r.date.day, () => <CalendarRecord>[]).add(r);
    }

    final firstDayOfMonth = DateTime(_ym.year, _ym.month, 1);
    final daysInMonth = DateTime(_ym.year, _ym.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7;
    final leadingEmpty = startWeekday;
    final totalCells = leadingEmpty + daysInMonth;
    final weeks = (totalCells / 7).ceil();
    final gridCount = weeks * 7;
    final needsScroll = weeks == 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalendarHeader(
          value: _ym,
          onChanged: (picked) {
            setState(() => _ym = picked);
            ctrl.changeMonth(DateTime(picked.year, picked.month, 1));
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              for (final label in const ['일', '월', '화', '수', '목', '금', '토'])
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.text_color1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.builder(
            physics: needsScroll
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: _cellWidth / _cellHeight,
            ),
            itemCount: gridCount,
            itemBuilder: (_, index) {
              final col = index % 7;
              final row = index ~/ 7;
              final isFirstCol = col == 0;
              final isFirstRow = row == 0;

              final day = index - leadingEmpty + 1;
              final inMonth = day >= 1 && day <= daysInMonth;

              final items = inMonth
                  ? (dayMap[day] ?? const <CalendarRecord>[])
                  : const <CalendarRecord>[];

              return CalendarDayCell(
                date: inMonth
                    ? DateTime(_ym.year, _ym.month, day)
                    : DateTime(_ym.year, _ym.month, 1),
                items: items,
                isPlaceholder: !inMonth,
                isFirstColumn: isFirstCol,
                isFirstRow: isFirstRow,
                onTapRecord: (recordId) =>
                    showRecordCardPreviewFromRecordId(context, ref, recordId),
                formatHHMM: ctrl.formatHHMM,
              );
            },
          ),
        ),
      ],
    );
  }
}

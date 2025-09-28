import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/calendar/widget/calendar_day_cell.dart';
import 'package:moods/features/calendar/dropdown/calendar_header.dart'
    show CalendarHeader, YearMonth;
import 'package:moods/features/calendar/dropdown/calendar_date_picker.dart'
    show showCalendarDatePicker;

// 너희 컨트롤러/상태
import 'package:moods/features/calendar/calendar_controller.dart';
import 'package:moods/features/calendar/calendar_service.dart'
    show CalendarVisitItem;
import 'package:moods/providers.dart'; // calendarControllerProvider 가 여기 있다면

/// 달력 전체 위젯 (상단 헤더 + 요일행 + 달력 그리드)
class CalendarWidget extends ConsumerStatefulWidget {
  const CalendarWidget({super.key});

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  YearMonth _ym = YearMonth.now();

  @override
  void initState() {
    super.initState();
    // 첫 진입 1회 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(calendarControllerProvider.notifier).loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarControllerProvider);

    // 컨트롤러에서 받은 전체 버킷 → 현재 월에 해당하는 것만 필터
    final monthBuckets = state.items.where(
      (b) => b.date.year == _ym.year && b.date.month == _ym.month,
    );

    // 날짜 → 그 날의 아이템들 맵
    final Map<int, List<CalendarVisitItem>> dayMap = {};
    for (final b in monthBuckets) {
      dayMap[b.date.day] = b.items;
    }

    // 달력 계산
    final firstDayOfMonth = DateTime(_ym.year, _ym.month, 1);
    final int daysInMonth = DateTime(
      _ym.year,
      _ym.month + 1,
      0,
    ).day; // 다음달 0일 = 이번달 말일
    final int startWeekday = firstDayOfMonth.weekday; // 월=1 … 일=7
    final int leadingEmpty = (startWeekday % 7); // 월=1→1칸 비움, 일=7→0칸 비움

    final int totalCells = leadingEmpty + daysInMonth;
    final int weeks = (totalCells / 7).ceil().clamp(5, 6); // 5주 또는 6주만 사용
    final int gridCount = weeks * 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ───── 헤더 (연/월 + ▼) ─────
        // 기존 (❌ onTap 존재하지 않음)
        CalendarHeader(
          value: _ym,
          onChanged: (picked) {
            setState(() => _ym = picked);
          },
        ),
        const SizedBox(height: 8),

        // ───── 요일 행 ─────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _WeekLabel('월'),
              _WeekLabel('화'),
              _WeekLabel('수'),
              _WeekLabel('목'),
              _WeekLabel('금'),
              _WeekLabel('토'),
              _WeekLabel('일'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ───── 달력 그리드 (경계선 없음) ─────
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, // 요일 7칸
            mainAxisSpacing: 18, // 셀 간 세로 간격
            crossAxisSpacing: 12, // 셀 간 가로 간격
          ),
          itemCount: gridCount,
          itemBuilder: (ctx, index) {
            final dayNumber = index - leadingEmpty + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              // 이전/다음달 영역 → 빈 칸(경계선 없음)
              return const SizedBox.shrink();
            }

            final items = dayMap[dayNumber] ?? const <CalendarVisitItem>[];
            return CalendarDayCell(
              date: DateTime(_ym.year, _ym.month, dayNumber),
              items: items, // 기록 없으면 빈 배열 → 백지 + 하단 날짜만
            );
          },
        ),

        // 하단 다음 달 제목(디자인 참고용)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Text(
            '${_nextYearMonth(_ym).year}년 ${_nextYearMonth(_ym).month}월',
            style: AppTextStyles.subtitle,
          ),
        ),

        // 상태 뱃지/로딩/에러 간단 표시(디버깅용)
        if (state.loading && !state.loadedOnce)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '오류: ${state.error}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  YearMonth _nextYearMonth(YearMonth ym) {
    final m = ym.month + 1;
    if (m == 13) return YearMonth(ym.year + 1, 1);
    return YearMonth(ym.year, m);
  }
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.small.copyWith(color: AppColors.text_color2),
    );
  }
}

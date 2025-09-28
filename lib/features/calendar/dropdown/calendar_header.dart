import 'package:flutter/material.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/features/calendar/dropdown/calendar_date_picker.dart';

/// 간단한 연/월 모델
class YearMonth {
  final int year;
  final int month;
  const YearMonth(this.year, this.month);

  factory YearMonth.now() {
    final now = DateTime.now();
    return YearMonth(now.year, now.month);
  }

  YearMonth copyWith({int? year, int? month}) =>
      YearMonth(year ?? this.year, month ?? this.month);

  @override
  String toString() => '$year년 $month월';

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

/// 상단 헤더: "2025년 7월 ▼"
/// - 탭하면 커스텀 날짜 피커(showCalendarDatePicker) 표시
/// - 선택된 YearMonth를 onChanged로 전달
class CalendarHeader extends StatelessWidget {
  final YearMonth value;
  final ValueChanged<YearMonth>? onChanged;
  final EdgeInsetsGeometry padding;
  final bool showDivider;

  const CalendarHeader({
    super.key,
    required this.value,
    this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.showDivider = false,
  });

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showCalendarDatePicker(
      context,
      initial: value,
      yearMin: 2024,
      yearMax: 2030,
    );
    if (picked != null && onChanged != null) {
      onChanged!(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openPicker(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.year}년 ${value.month}월',
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more, size: 22, color: Colors.black),
                ],
              ),
            ),
          ),
          if (showDivider)
            const Divider(height: 1, thickness: 1, color: AppColors.border),
        ],
      ),
    );
  }
}

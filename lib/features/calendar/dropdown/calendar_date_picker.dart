// lib/features/calendar/dropdown/calendar_date_picker.dart
import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/calendar/dropdown/calendar_header.dart'
    show YearMonth;

/// 사용 예)
/// final picked = await showCalendarDatePicker(context, initial: YearMonth.now());
/// if (picked != null) { /* 컨트롤러로 전달 */ }
Future<YearMonth?> showCalendarDatePicker(
  BuildContext context, {
  required YearMonth initial,
  int yearMin = 2024,
  int yearMax = 2030,
}) {
  return showDialog<YearMonth?>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CalendarDatePickerDialog(
      initial: initial,
      yearMin: yearMin,
      yearMax: yearMax,
    ),
  );
}

class _CalendarDatePickerDialog extends StatefulWidget {
  const _CalendarDatePickerDialog({
    required this.initial,
    required this.yearMin,
    required this.yearMax,
  });

  final YearMonth initial;
  final int yearMin;
  final int yearMax;

  @override
  State<_CalendarDatePickerDialog> createState() =>
      _CalendarDatePickerDialogState();
}

class _CalendarDatePickerDialogState extends State<_CalendarDatePickerDialog> {
  late int _year;
  late int _month;

  late final FixedExtentScrollController _yearCtrl;
  late final FixedExtentScrollController _monthCtrl;

  List<int> get _years => List<int>.generate(
    widget.yearMax - widget.yearMin + 1,
    (i) => widget.yearMin + i,
  );

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year.clamp(widget.yearMin, widget.yearMax);
    _month = widget.initial.month.clamp(1, 12);

    _yearCtrl = FixedExtentScrollController(initialItem: _years.indexOf(_year));
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 329,
        height: 300,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('다른 날짜 보기', style: AppTextStyles.body),
              const SizedBox(height: 12),

              // ── 휠 영역 ─────────────────────────────────────────
              // ── 날짜 휠 영역 (한 줄만 교체)
              // ── 날짜 휠 영역
              // ── 날짜 휠 영역
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 140,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // ✅ 중앙 하이라이트 바
                      const SizedBox(
                        width: 296,
                        height: 28,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.sub,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                      ),

                      // ✅ 휠 (offset으로 조정 가능)
                      Row(
                        children: [
                          // 왼쪽(년도)
                          Expanded(
                            child: Transform.translate(
                              offset: const Offset(
                                25,
                                0,
                              ), // 👉 x값 키우면 오른쪽으로, 줄이면 왼쪽으로
                              child: _Wheel(
                                controller: _yearCtrl,
                                itemCount: _years.length,
                                itemBuilder: (i) => Text(
                                  '${_years[i]}년',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.small.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _years[i] == _year
                                        ? Colors.white
                                        : AppColors.text_color2,
                                  ),
                                ),
                                onSelectedItemChanged: (i) =>
                                    setState(() => _year = _years[i]),
                              ),
                            ),
                          ),

                          // 오른쪽(월)
                          Expanded(
                            child: Transform.translate(
                              offset: const Offset(
                                -25,
                                0,
                              ), // 👉 x값 키우면 왼쪽으로, 줄이면 오른쪽으로
                              child: _Wheel(
                                controller: _monthCtrl,
                                itemCount: 12,
                                itemBuilder: (i) => Text(
                                  '${i + 1}월',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.small.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: (i + 1) == _month
                                        ? Colors.white
                                        : AppColors.text_color2,
                                  ),
                                ),
                                onSelectedItemChanged: (i) =>
                                    setState(() => _month = i + 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ───────────────────────────────────────────────────
              const Spacer(),

              // 확인 버튼 (297 x 50, r=30)
              Center(
                child: SizedBox(
                  width: 297,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sub,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(YearMonth(_year, _month));
                    },
                    child: Text(
                      '확인',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 공통 휠 (하이라이트는 부모가 덮어쓰므로 여기서는 스크롤만)
class _Wheel extends StatelessWidget {
  const _Wheel({
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.onSelectedItemChanged,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final Widget Function(int) itemBuilder;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      physics: const FixedExtentScrollPhysics(),
      itemExtent: 28, // 하이라이트 높이에 맞춰 28
      perspective: 0.001,
      diameterRatio: 2.2,
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        builder: (ctx, i) => (i == null || i < 0 || i >= itemCount)
            ? null
            : Center(child: itemBuilder(i)),
      ),
    );
  }
}

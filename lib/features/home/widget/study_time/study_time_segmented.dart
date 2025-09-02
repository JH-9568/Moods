// lib/features/home/widget/study_time/study_time_segmented.dart
import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/study_time/study_time_controller.dart' show StudyTotalRange;

class StudyTimeSegmented extends StatelessWidget {
  final StudyTotalRange value;
  final ValueChanged<StudyTotalRange> onChanged;
  final double width;

  const StudyTimeSegmented({
    Key? key,
    required this.value,
    required this.onChanged,
    this.width = 100, // 버튼 전체 폭 (이번 달/이번 주 나눠서)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double height = 24;
    const double radius = 20;
    const double outerPadding = 3;

    final bool isMonth = value == StudyTotalRange.month;

    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double trackWidth = constraints.maxWidth;
          final double thumbWidth = (trackWidth - outerPadding * 2) / 2;

          return Stack(
            children: [
              // 전체 트랙 (sub 색상)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.sub,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),

              // 흰색 슬라이드 thumb
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                left: isMonth ? outerPadding : (trackWidth / 2) + outerPadding,
                top: outerPadding,
                bottom: outerPadding,
                width: thumbWidth - outerPadding,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(radius - 2),
                  ),
                ),
              ),

              // 텍스트 + 터치 영역
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(radius),
                      onTap: () => onChanged(StudyTotalRange.month),
                      child: Center(
                        child: Text(
                          '이번 달',
                          style: AppTextStyles.small.copyWith(
                            color: isMonth ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(radius),
                      onTap: () => onChanged(StudyTotalRange.week),
                      child: Center(
                        child: Text(
                          '이번 주',
                          style: AppTextStyles.small.copyWith(
                            color: isMonth ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
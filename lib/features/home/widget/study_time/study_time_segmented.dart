// lib/features/home/widget/study_time/study_time_segmented.dart
import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'study_time_controller.dart' show StudyScope;

/// 기존 디자인(흰색 thumb가 움직이는 토글)을 유지하면서,
/// 컨트롤러의 StudyScope(month/week)에 바로 연결되도록 한 버전.
class StudyTimeSegmented extends StatelessWidget {
  final StudyScope value;
  final ValueChanged<StudyScope> onChanged;
  final double width;

  const StudyTimeSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 90, // 필요 시 외부에서 폭 조절
  });

  @override
  Widget build(BuildContext context) {
    const double height = 24;
    const double radius = 20;
    const double outerPadding = 2.5;

    final bool isMonth = value == StudyScope.month;

    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double trackWidth = constraints.maxWidth;
          final double thumbWidth = (trackWidth - outerPadding * 2) / 2;

          return Stack(
            children: [
              // 전체 트랙
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
                      onTap: () => onChanged(StudyScope.month),
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
                      onTap: () => onChanged(StudyScope.week),
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

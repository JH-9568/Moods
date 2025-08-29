// lib/features/home/widget/study_time/study_time_segmented.dart
// 역할: "이번 달 / 이번 주" 세그먼티드 컨트롤

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moods/features/home/widget/study_time/study_time_provider.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';

class StudyTimeSegmented extends StatelessWidget {
  final StudyTotalRange value;
  final ValueChanged<StudyTotalRange> onChanged;
  final double width;

  const StudyTimeSegmented({
    Key? key,
    required this.value,
    required this.onChanged,
    this.width = 110,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double height = 24;
    const double radius = 20; // pill
    const double outerPadding = 3; // 바깥 여백(트랙과 thumb 사이의 링 두께)

    final bool isMonth = value == StudyTotalRange.month;

    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double trackWidth = constraints.maxWidth;
          final double thumbWidth = (trackWidth - outerPadding * 2) / 2; // 반쪽

          return Stack(
            children: [
              // Track (비선택 영역)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.sub, // 트랙 색
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),

              // Sliding white thumb + SUB 컬러 링(트랙을 노출해서 링처럼 보이게)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                left: isMonth ? outerPadding : (trackWidth / 2) + outerPadding - 0.0,
                top: outerPadding,
                bottom: outerPadding,
                width: thumbWidth - outerPadding, // 바깥 여백만큼 줄여 링을 만들기 위함
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(radius - 2),
                    // 외곽 테두리를 더 강조하고 싶으면 아래 보더 라인을 풀어서 사용
                    // border: Border.all(color: AppColors.sub, width: 1.5),
                    
                  ),
                ),
              ),

              // Labels + 터치 영역
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
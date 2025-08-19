import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';

class StudyCountWidget extends StatelessWidget {
  final int studyCount;
  const StudyCountWidget({super.key, required this.studyCount});

  @override
  Widget build(BuildContext context) {
    // 25회 이후도 자연스럽게 표시되도록, 다음 5회 단위까지 범위를 확장
    final int maxCap = math.max(25, ((studyCount + 4) ~/ 5) * 5);
    final double ratio = (studyCount / maxCap).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '나의 공부 횟수',
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.text_color1),
        ),
        const SizedBox(height: 2),

        // Stack을 사용해서 라벨을 원 위에 정확히 위치시키기
        LayoutBuilder(
          builder: (context, constraints) {
            final double railWidth = constraints.maxWidth * 0.93; // 레일 길이 조정
            final double railOffset = (constraints.maxWidth - railWidth) / 2; // 중앙 정렬을 위한 오프셋

            return SizedBox(
              height: 50, // 라벨 공간까지 포함한 전체 높이
              child: Stack(
                children: [
                  // 라벨들 (위쪽에 위치, 레일 위치에 맞춰 조정)
                  Positioned(
                    top: 5,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 22,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const double labelWidth = 36; // 라벨 박스 고정 너비 (텍스트 중앙 정렬, 20/25 활성시도 여유)
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (int i = 0; i <= 5; i++)
                                Builder(
                                  builder: (context) {
                                    final double idealCenter = railOffset + (railWidth * (i / 5));
                                    final double left = (idealCenter - (labelWidth / 2))
                                        .clamp(0.0, constraints.maxWidth - labelWidth);
                                    // 라벨 박스는 부모 경계 내에 유지(clamp)하되, 텍스트는 내부에서 미세 이동시켜
                                    // 이상적인 중앙(idealCenter)에 정확히 일치시키는 방식
                                    final double innerShift = idealCenter - (left + labelWidth / 2);
                                    return Positioned(
                                      left: left,
                                      child: SizedBox(
                                        width: labelWidth,
                                        height: 22, // 활성(굵게/큰 폰트) 시 상하 여유
                                        child: Transform.translate(
                                          offset: Offset(innerShift, 0),
                                          child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Padding(
                                              padding: const EdgeInsets.only(bottom: 1),
                                              child: _buildLabel('${i * 5}회', i * 5, studyCount),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  // 진행바 (아래쪽에 위치, 중앙 정렬)
                  Positioned(
                    bottom: 0,
                    left: railOffset,
                    child: CustomPaint(
                      size: Size(railWidth, 32),
                      painter: _StudyProgressPainter(
                        ratio: ratio,
                        studyCount: studyCount,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLabel(String text, int value, int currentCount) {
    final bool isActive = currentCount == value;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isActive ? 14 : 12,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
        color: isActive ? AppColors.text_color1 : Color.fromRGBO(175, 175, 175, 1),
      ),
    );
  }
}

class _StudyProgressPainter extends CustomPainter {
  final double ratio; // 0.0 ~ 1.0 (부분 진행 지원)
  final int studyCount;
  static const double _railHeight = 8;
  static const double _tickRadius = 8;

  const _StudyProgressPainter({
    required this.ratio,
    required this.studyCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;

    // 배경 레일
    final Paint railPaint = Paint()
      ..color = AppColors.unchecked
      ..style = PaintingStyle.fill;
    final RRect baseRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, centerY - _railHeight / 2, size.width, _railHeight),
      const Radius.circular(_railHeight / 2),
    );
    canvas.drawRRect(baseRRect, railPaint);

    // 채워진 레일 (지나온 부분은 sub 색상)
    final Paint fillPaint = Paint()
      ..color = AppColors.sub
      ..style = PaintingStyle.fill;
    final double fillWidth = size.width * ratio;
    final RRect fillRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, centerY - _railHeight / 2, fillWidth, _railHeight),
      const Radius.circular(_railHeight / 2),
    );
    canvas.drawRRect(fillRRect, fillPaint);

    // 0~25 눈금 그리기
    final Paint grayTickPaint = Paint()
      ..color = AppColors.unchecked
      ..style = PaintingStyle.fill;
    final Paint completedTickPaint = Paint()
      ..color = AppColors.sub
      ..style = PaintingStyle.fill;
    final Paint currentTickPaint = Paint()
      ..color = AppColors.main
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= 5; i++) {
      final double x = size.width * (i / 5);
      final int tickValue = i * 5; // 0, 5, 10, 15, 20, 25

      Paint tickPaint;
      if (studyCount == tickValue) {
        // 현재 위치는 main 색상
        tickPaint = currentTickPaint;
      } else if (studyCount > tickValue) {
        // 지나온 위치는 sub 색상
        tickPaint = completedTickPaint;
      } else {
        // 아직 달성하지 않은 위치는 unchecked 색상
        tickPaint = grayTickPaint;
      }

      canvas.drawCircle(Offset(x, centerY), _tickRadius, tickPaint);
    }

    // 5의 배수일 때는 별도의 진행 썸을 그리지 않음 (눈금 원으로 충분)
    // 5의 배수가 아닐 때는 진행 썸도 그리지 않음 (레일만 표시)
  }

  @override
  bool shouldRepaint(covariant _StudyProgressPainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.studyCount != studyCount;
  }
}
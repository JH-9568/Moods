// lib/features/home/widget/my_moods/study_count_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';

// ✅ 총 공부횟수 컨트롤러(프로바이더) 임포트
import 'package:moods/features/home/widget/study_count/study_count_controller.dart';

class StudyCountWidget extends ConsumerWidget {
  const StudyCountWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(studyCountControllerProvider);
    final notifier = ref.read(studyCountControllerProvider.notifier);

    // 첫 렌더 후 한 번만 API 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.loadIfNeeded();
    });

    // API로부터 받은 총 공부 횟수 (로딩 중엔 0으로 표시해도 디자인 무너짐 없음)
    final int studyCount = st.totalCount;

    // ===== 아래부터는 네가 만든 "디자인 로직" 그대로 =====

    // 창(window) 시작은 항상 25의 배수: 0~24→0, 25~49→25, 50~74→50 ...
    final int windowStart = (studyCount ~/ 25) * 25;
    const int windowSpan = 25; // 항상 25 폭(0~25, 25~50 ...)

    // 윈도우 내 진행도(0~25)
    final int localProgress = studyCount - windowStart; // 0..25..
    final bool isExactMultiple = studyCount % 5 == 0; // 5의 배수 여부

    // 스냅 기준(5의 배수)은 윈도우 안에서 계산 후, 다시 절대값으로 환산
    final int anchorLocal =
        (localProgress ~/ 5) * 5; // 7→5, 9→5, 10→10 (윈도우 기준)
    final int anchorCount = windowStart + anchorLocal; // 절대 카운트로 환산

    // 썸(원) 위치: 배수면 anchor, 아니면 구간 중앙(anchor+2.5)
    final double logicalCountForThumb = isExactMultiple
        ? anchorCount.toDouble()
        : (anchorCount + 2.5);

    // 윈도우 내 비율
    final double thumbRatio =
        ((logicalCountForThumb - windowStart) / windowSpan).clamp(0.0, 1.0);
    // 레일 채움은 썸 위치까지
    final double fillRatio = thumbRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '나의 총 공부 횟수',
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.text_color1),
        ),
        const SizedBox(height: 2),

        // (옵션) 에러가 있으면 살짝 안내
        if (st.error != null && st.error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              st.error!,
              style: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),

        // Stack을 사용해서 라벨을 원 위에 정확히 위치시키기
        LayoutBuilder(
          builder: (context, constraints) {
            final double railWidth = constraints.maxWidth * 0.93; // 레일 길이 조정
            final double railOffset =
                (constraints.maxWidth - railWidth) / 2; // 중앙 정렬을 위한 오프셋

            const double railTail = 12.0; // px
            final double usableRailWidth =
                railWidth - railTail; // 틱/채움/썸은 여기까지만 배치
            // 페인터의 원 반지름과 동일한 인셋을 적용해 꼬리가 더 분명히 보이도록
            const double tickInset =
                6.0; // _StudyProgressPainter._tickRadius 와 동일
            final double effectiveRailWidth =
                usableRailWidth - 2 * tickInset; // 틱/썸이 실제로 분포하는 가로 길이
            final double baseX = railOffset + tickInset; // 첫 틱의 중심 X

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
                          const double labelWidth =
                              36; // 라벨 박스 고정 너비 (텍스트 중앙 정렬, 20/25 활성시도 여유)
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (int i = 0; i <= 5; i++)
                                Builder(
                                  builder: (context) {
                                    final double idealCenter =
                                        baseX + (effectiveRailWidth * (i / 5));
                                    final double left =
                                        (idealCenter - (labelWidth / 2)).clamp(
                                          0.0,
                                          constraints.maxWidth - labelWidth,
                                        );
                                    // 라벨 박스는 부모 경계 내에 유지(clamp)하되, 텍스트는 내부에서 미세 이동시켜
                                    // 이상적인 중앙(idealCenter)에 정확히 일치시키는 방식
                                    final double innerShift =
                                        idealCenter - (left + labelWidth / 2);
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
                                              padding: const EdgeInsets.only(
                                                bottom: 1,
                                              ),
                                              child: _buildLabel(
                                                '${windowStart + i * 5}회',
                                                windowStart + i * 5,
                                                isExactMultiple
                                                    ? studyCount
                                                    : -1,
                                              ),
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
                        fillRatio: fillRatio,
                        thumbRatio: thumbRatio,
                        studyCount: studyCount,
                        windowStart: windowStart,
                      ),
                    ),
                  ),

                  // 현재 카운트 라벨 (floating label)
                  if (studyCount > 0 && !isExactMultiple)
                    Positioned(
                      top: 5,
                      left: () {
                        final TextStyle style = AppTextStyles.bodyBold.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.main,
                        );
                        final String numText = '$studyCount';
                        const String unitText = '회';

                        // 숫자와 '회'를 각각 측정
                        final TextPainter numTp = TextPainter(
                          text: TextSpan(text: numText, style: style),
                          textDirection: TextDirection.ltr,
                        )..layout();
                        final TextPainter unitTp = TextPainter(
                          text: TextSpan(text: unitText, style: style),
                          textDirection: TextDirection.ltr,
                        )..layout();

                        final double numericWidth = numTp.width;
                        final double labelWidth = numericWidth + unitTp.width;

                        // 썸(원) 중심
                        final double tRatio = thumbRatio.isFinite
                            ? thumbRatio
                            : 0.0;
                        final double idealCenter =
                            baseX + (effectiveRailWidth * tRatio);

                        // 문자열 전체의 중앙이 thumbCenter와 일치하도록
                        double left = idealCenter - (labelWidth / 2);

                        // 틱 밴드 내에서만 보이도록 클램프
                        final double minLeft = baseX;
                        final double maxLeft =
                            baseX + effectiveRailWidth - labelWidth;
                        if (left < minLeft) left = minLeft;
                        if (left > maxLeft) left = maxLeft;
                        return left;
                      }(),
                      child: SizedBox(
                        // 실측 폭을 그대로 사용해 텍스트가 잘리지 않도록 함
                        width: () {
                          final TextStyle style = AppTextStyles.bodyBold
                              .copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.main,
                              );
                          final String numText = '$studyCount';
                          const String unitText = '회';
                          final TextPainter numTp = TextPainter(
                            text: TextSpan(text: numText, style: style),
                            textDirection: TextDirection.ltr,
                          )..layout();
                          final TextPainter unitTp = TextPainter(
                            text: TextSpan(text: unitText, style: style),
                            textDirection: TextDirection.ltr,
                          )..layout();
                          return numTp.width + unitTp.width;
                        }(),
                        height: 22,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.bodyBold.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.main,
                                ),
                                children: [
                                  TextSpan(text: '$studyCount'),
                                  const TextSpan(text: '회'),
                                ],
                              ),
                            ),
                          ),
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
    final bool isActive = currentCount == value; // 현재 값이 5의 배수일 때 해당 눈금만 강조
    return Text(
      text,
      textAlign: TextAlign.center,
      style: isActive
          ? AppTextStyles.bodyBold.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.main,
            )
          : const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color.fromRGBO(175, 175, 175, 1),
            ),
    );
  }
}

class _StudyProgressPainter extends CustomPainter {
  final double fillRatio; // 0.0 ~ 1.0, 레일 채움 비율(썸까지)
  final double thumbRatio; // 0.0 ~ 1.0, 썸(원) 위치(중간 2.5 포함)
  final int studyCount; // 실제 카운트
  final int windowStart; // 윈도우 시작 값(예: 0, 25, 50 ...)
  static const double _railHeight = 6;
  static const double _tickRadius = 8;
  static const double _railTail = 12.0;
  static const double _tickInset = _tickRadius; // 틱 중심을 좌우로 반지름만큼 안쪽에 배치

  const _StudyProgressPainter({
    required this.fillRatio,
    required this.thumbRatio,
    required this.studyCount,
    required this.windowStart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerY = size.height / 2;
    final double usableWidth = size.width - _railTail;
    final double effectiveWidth = usableWidth - 2 * _tickInset; // 틱/썸 분포 길이
    final double base = _tickInset; // 첫 틱 중심 X

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
    final double fillWidth = base + (effectiveWidth * fillRatio);
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
      final double x = base + (effectiveWidth * (i / 5));
      final int tickValue = windowStart + i * 5; // 예: 25,30,35,40,45,50

      Paint tickPaint;
      final int anchor = (studyCount ~/ 5) * 5;
      final bool isExact = studyCount % 5 == 0;
      if (isExact && tickValue == anchor) {
        tickPaint = currentTickPaint; // 정확히 5의 배수인 현재 눈금
      } else if (tickValue <= anchor) {
        tickPaint = completedTickPaint; // 완료된 눈금
      } else {
        tickPaint = grayTickPaint; // 아직 도달하지 않음
      }

      canvas.drawCircle(Offset(x, centerY), _tickRadius, tickPaint);
    }

    // 현재 위치 썸(원) – 5의 배수면 해당 눈금, 아니면 구간 중앙(…+2.5)
    final Offset thumbCenter = Offset(
      base + (effectiveWidth * thumbRatio),
      centerY,
    );
    canvas.drawCircle(thumbCenter, _tickRadius, currentTickPaint);

    // 썸(원)은 위에서 그렸으며, 실제 카운트는 라벨(Stack)로 표시됩니다.
  }

  @override
  bool shouldRepaint(covariant _StudyProgressPainter oldDelegate) {
    return oldDelegate.fillRatio != fillRatio ||
        oldDelegate.thumbRatio != thumbRatio ||
        oldDelegate.studyCount != studyCount ||
        oldDelegate.windowStart != windowStart;
  }
}

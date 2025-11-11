// lib/features/my_page/space_study_count_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';

// 누적 공부 횟수
import 'package:moods/features/home/widget/study_count/study_count_controller.dart';
// 나의 공부 장소 개수
import 'package:moods/features/my_page/space_count/space_count_controller.dart';

/// 마이페이지 상단의 “공부 누적 횟수 / 나의 공부 장소” 박스 (329×69, r=8, 가운데 흰색 divider)
/// - 자체적으로 Riverpod 컨트롤러를 구독하여 API 연동 상태를 표시합니다.
/// - 부모는 그냥 const SpaceStudyCountWidget()만 배치하면 됩니다.
class SpaceStudyCountWidget extends ConsumerStatefulWidget {
  const SpaceStudyCountWidget({super.key});

  @override
  ConsumerState<SpaceStudyCountWidget> createState() =>
      _SpaceStudyCountWidgetState();
}

class _SpaceStudyCountWidgetState extends ConsumerState<SpaceStudyCountWidget> {
  @override
  void initState() {
    super.initState();
    // 첫 렌더 뒤 1회 로드(안전하게)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(studyCountControllerProvider.notifier).loadIfNeeded();
      ref.read(studySpaceCountControllerProvider.notifier).loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studyCount = ref.watch(studyCountControllerProvider);
    final spaceCount = ref.watch(studySpaceCountControllerProvider);

    final String studyCountText = (studyCount.loading && !studyCount.loadedOnce)
        ? '…'
        : '${studyCount.totalCount}';
    final String spaceCountText = (spaceCount.loading && !spaceCount.loadedOnce)
        ? '…'
        : '${spaceCount.totalSpaces}';

    return Container(
      width: 329,
      height: 69,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 왼쪽 지표: 공부 누적 횟수
          Expanded(
            child: _MetricCell(
              label: '공부 누적 횟수',
              valueText: studyCountText,
              unitText: '회',
            ),
          ),

          // 가운데 divider (흰색, 높이 살짝 줄임)
          SizedBox(
            width: 1,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              color: Colors.white,
            ),
          ),

          // 오른쪽 지표: 나의 공부 장소
          Expanded(
            child: _MetricCell(
              label: '나의 공부 장소',
              valueText: spaceCountText,
              unitText: '곳',
            ),
          ),
        ],
      ),
    );
  }
}

/// 한 칸(라벨 / 숫자 / 단위) 구성
class _MetricCell extends StatelessWidget {
  final String label;
  final String valueText;
  final String unitText;

  const _MetricCell({
    required this.label,
    required this.valueText,
    required this.unitText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 5),
          // 라벨
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              fontWeight: FontWeight.w600,
              // 테마 컬러와 관계없이 항상 동일한 색상을 사용
              color: Colors.black,
            ),
          ),

          // 값 + 단위
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valueText,
                style: AppTextStyles.title.copyWith(
                  height: 1.3,
                  color: AppColors.text_color1,
                ),
              ),
              const SizedBox(width: 7),
              // 단위만 Transform으로 위로 올림
              Transform.translate(
                offset: const Offset(0, -6),
                child: Text(
                  unitText,
                  style: AppTextStyles.body.copyWith(
                    color: const Color.fromRGBO(175, 175, 175, 1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

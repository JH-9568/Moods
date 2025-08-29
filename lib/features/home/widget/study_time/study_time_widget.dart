// lib/features/home/widget/study_time/study_time_widget.dart
import 'dart:ui'; // ImageFilter를 사용하기 위해 추가합니다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/study_time/study_time_controller.dart';
import 'package:moods/features/home/widget/study_time/study_time_provider.dart';
import 'package:moods/features/home/widget/study_time/study_time_segmented.dart';
import 'package:moods/features/home/widget/study_time/time_format.dart';

class TotalStudyTimeWidget extends ConsumerWidget {
  final bool showSegment;
  const TotalStudyTimeWidget({super.key, this.showSegment = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studyTimeControllerProvider);
    final ctrl = ref.read(studyTimeControllerProvider.notifier);

    final timeTextWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _TimeText(
        key: ValueKey('${state.loading}-${state.total.inSeconds}-${state.error}'),
        timeText: state.loading ? '00:00:00' : formatHms(state.total),
        dimmed: state.loading,
      ),
    );

    final errorWidget = state.error != null
        ? Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '불러오기 실패: ${state.error}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          )
        : const SizedBox.shrink();

    // 전체 위젯을 Stack으로 감싸서 배경을 맨 뒤에 배치합니다.
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // 1. 배경 위젯
        Padding(
          padding: const EdgeInsets.only(top: 50),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
              child: Container(
                width: 151,
                height: 151,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EBF8).withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),

        // 2. 기존 컨텐츠 (Segmented Control, 타이머 등)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSegment)
              Padding(
                padding: const EdgeInsets.only(top: 28.0, bottom: 5.0),
                child: StudyTimeSegmented(
                  value: state.range,
                  onChanged: (r) => ctrl.setRange(r),
                ),
              ),
            timeTextWidget,
            errorWidget,
          ],
        ),
      ],
    );
  }
}

/// 시간 텍스트만 표시하는 단순한 위젯입니다.
class _TimeText extends StatelessWidget {
  final String timeText;
  final bool dimmed;
  const _TimeText({super.key, required this.timeText, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? Colors.black.withOpacity(0.25) : Colors.black;

    return SizedBox(
      width: 225,
      height: 65,
      child: Center(
        child: Text(
          timeText,
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle.copyWith(
            fontSize: 50,
            height: 1.3,
            letterSpacing: -0.2,
            color: color,
          ),
        ),
      ),
    );
  }
}

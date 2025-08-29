// lib/features/home/widget/study_time/study_time_widget.dart
// 역할: 세그먼트 + 대형 타이머 표시를 묶은 실제 위젯
// NOTE: 기존 코드 호환을 위해 showSegment 파라미터를 지원합니다(기본 true).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/home/widget/study_time/study_time_controller.dart';
import 'package:moods/features/home/widget/study_time/study_time_provider.dart';
import 'package:moods/features/home/widget/study_time/study_time_segmented.dart';
import 'package:moods/features/home/widget/study_time/time_format.dart';

class TotalStudyTimeWidget extends ConsumerWidget {
  final bool showSegment; // 기존 호출부 호환용 (없으면 true)
  const TotalStudyTimeWidget({super.key, this.showSegment = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studyTimeControllerProvider);
    final ctrl = ref.read(studyTimeControllerProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSegment)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
            child: StudyTimeSegmented(
              value: state.range,
              onChanged: (r) => ctrl.setRange(r),
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _TimeText(
            key: ValueKey('${state.loading}-${state.total.inSeconds}-${state.error}'),
            timeText: state.loading
                ? '00:00:00'
                : formatHms(state.total), // 누적 시간을 HH:MM:SS로 표시
            dimmed: state.loading,
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '불러오기 실패: ${state.error}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }
}

/// 시간 텍스트만 분리 (큰 숫자 표시)
class _TimeText extends StatelessWidget {
  final String timeText;
  final bool dimmed;
  const _TimeText({super.key, required this.timeText, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? Colors.black.withOpacity(0.25) : Colors.black;
    return Text(
      timeText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 50, // 필요 시 조절
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: color,
      ),
    );
  }
}
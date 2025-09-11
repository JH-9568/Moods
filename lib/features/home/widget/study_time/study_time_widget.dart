// lib/features/home/widget/study_time/study_time_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blur/blur.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'study_time_controller.dart';
import 'study_time_segmented.dart';

class StudyTimeWidget extends ConsumerWidget {
  const StudyTimeWidget({super.key, this.showSegment = true});
  final bool showSegment;

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${two(h)}:${two(m)}:${two(s)}';
    // 필요하면 24시간 넘어갈 때 days*24+h 로 확장할 수 있음
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(studyTimeControllerProvider);
    final notifier = ref.read(studyTimeControllerProvider.notifier);

    // 첫 렌더 직후 1회 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.loadIfNeeded();
    });

    return Container(
      width: 361,
      height: 276,
      decoration: BoxDecoration(
        color: AppColors.background, // 요구대로 background
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: st.loading && !st.loadedOnce
            ? const CircularProgressIndicator()
            : Stack(
                alignment: Alignment.topCenter,
                children: [
                  // 배경 Glow
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Blur(
                      blur: 15,
                      borderRadius: BorderRadius.circular(180),
                      blurColor: const Color(0xFFE8EBF8).withOpacity(0.7),
                      child: Container(
                        width: 151,
                        height: 151,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                      ),
                    ),
                  ),

                  // 세그먼트 + 큰 시간 + 에러
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showSegment)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 28.0,
                            bottom: 5.0,
                          ),
                          child: StudyTimeSegmented(
                            // 네가 쓰는 segmented 디자인/타입에 맞게 StudyScope 전달
                            value: st.scope,
                            onChanged: (scope) => notifier.setScope(scope),
                          ),
                        ),

                      // 큰 시간 (초 포함)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: SizedBox(
                          key: ValueKey(st.current.inSeconds),
                          width: 225,
                          height: 65,
                          child: Center(
                            child: Text(
                              _fmt(st.current),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.subtitle.copyWith(
                                fontSize: 50,
                                height: 1.3,
                                letterSpacing: -0.2,
                                color: st.loading
                                    ? Colors.black.withOpacity(0.25)
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 에러 있으면 표시
                      if (st.error != null && st.error!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            st.error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

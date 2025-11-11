// lib/features/home/widget/study_time/study_time_widget.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:blur/blur.dart'; // 제거: Layer blur는 ImageFiltered로 구현

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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(studyTimeControllerProvider);
    final notifier = ref.read(studyTimeControllerProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.loadIfNeeded();
    });

    return Container(
      width: 361,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: st.loading && !st.loadedOnce
            ? const CircularProgressIndicator()
            : Stack(
                // 넘치는 블러 효과가 잘리지 않도록 클리핑을 끈다
                clipBehavior: Clip.none,
                children: [
                  // Figma: Layer blur 원 (X=121, Y=131, W=151, H=151)
                  // Stack 안에서
                  Align(
                    alignment: Alignment.topCenter, // 가로축은 가운데 고정
                    child: Transform.translate(
                      offset: const Offset(0, 5), // Y축으로 40px 내려줌 (원하는 값으로 조정)
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Opacity(
                          opacity: 0.9,
                          child: Container(
                            width: 151,
                            height: 151,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromRGBO(224, 216, 209, 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 콘텐츠(세그먼트 + 시간 + 에러)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showSegment)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 28.0,
                              bottom: 5.0,
                            ),
                            child: StudyTimeSegmented(
                              value: st.scope,
                              onChanged: (scope) => notifier.setScope(scope),
                            ),
                          ),
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
                        if (st.error != null && st.error!.isNotEmpty)
                          const SizedBox(height: 6),
                        if (st.error != null && st.error!.isNotEmpty)
                          Text(
                            st.error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

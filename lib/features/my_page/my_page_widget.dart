// lib/features/my_page/my_page_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/features/my_page/setting/setting_widget.dart';

// 구성요소 위젯들
import 'package:moods/features/my_page/user_profile/user_profile_widget.dart';
import 'package:moods/features/my_page/space_study_count_widget.dart';
import 'package:moods/features/my_page/my_page_study_record_widget.dart';

// 통계 로딩 트리거(누적횟수 / 장소개수) — 위젯 내부에서 처리해도 되지만
// 진입 즉시 한번 보장해주려고 initState에서 불러줍니다.
import 'package:moods/features/home/widget/study_count/study_count_controller.dart';
import 'package:moods/features/my_page/space_count/space_count_controller.dart';

class MyPageWidget extends ConsumerStatefulWidget {
  const MyPageWidget({super.key});

  @override
  ConsumerState<MyPageWidget> createState() => _MyPageWidgetState();
}

class _MyPageWidgetState extends ConsumerState<MyPageWidget> {
  static const double _headerHeight = 335.0;

  @override
  void initState() {
    super.initState();
    // 첫 진입 시 통계값 로드 (위젯 내부에서도 loadIfNeeded를 하더라도 중복 호출 방지됨)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(studyCountControllerProvider.notifier).loadIfNeeded();
      ref.read(studySpaceCountControllerProvider.notifier).loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusBar = MediaQuery.of(context).padding.top;
    const headerColor = Color.fromRGBO(208, 215, 248, 1);

    return Scaffold(
      // ⬅️ Scaffold 배경을 headerColor로
      backgroundColor: headerColor,
      body: Column(
        children: [
          // 상태바 영역
          Container(height: statusBar, color: headerColor),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ───────── 헤더 영역 ─────────
                  Container(
                    width: double.infinity,
                    height: _headerHeight,
                    color: headerColor,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 16,
                          right: 16,
                          top: 230,
                          child: const UserProfileWidget(),
                        ),
                      ],
                    ),
                  ),

                  // ───────── 본문 영역 (배경 = background) ─────────
                  Container(
                    width: double.infinity,
                    color: AppColors.background,
                    child: Column(
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -34),
                          child: const SpaceStudyCountWidget(),
                        ),
                        const SizedBox(height: 0),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: MyPageStudyRecordWidget(),
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: SettingSection(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

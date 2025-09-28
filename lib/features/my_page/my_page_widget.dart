// lib/features/my_page/my_page_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/features/my_page/setting/setting_widget.dart';

// 구성요소 위젯들
import 'package:moods/features/my_page/user_profile/user_profile_widget.dart';
import 'package:moods/features/my_page/space_study_count_widget.dart';
import 'package:moods/features/my_page/my_page_study_record_widget.dart';

// 통계 로딩 트리거
import 'package:moods/features/home/widget/study_count/study_count_controller.dart';
import 'package:moods/features/my_page/space_count/space_count_controller.dart';

class MyPageWidget extends ConsumerStatefulWidget {
  const MyPageWidget({super.key});

  @override
  ConsumerState<MyPageWidget> createState() => _MyPageWidgetState();
}

class _MyPageWidgetState extends ConsumerState<MyPageWidget> {
  static const double _headerTotalHeight = 335.0;
  static const double _profileTop = 165.0;
  static const double _countLift = -42.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(studyCountControllerProvider.notifier).loadIfNeeded();
      ref.read(studySpaceCountControllerProvider.notifier).loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double statusBar = MediaQuery.of(context).padding.top;
    const headerColor = AppColors.main;

    return Scaffold(
      backgroundColor: headerColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ───────── 헤더 ─────────
            Container(
              width: double.infinity,
              height: _headerTotalHeight,
              color: headerColor,
              padding: EdgeInsets.only(top: statusBar),
              child: Stack(
                children: [
                  // 프로필 카드
                  const Positioned(
                    left: 16,
                    right: 16,
                    top: _profileTop,
                    child: UserProfileWidget(),
                  ),

                  // PNG 아이콘 추가
                ],
              ),
            ),

            // ───────── 본문 영역 ─────────
            Container(
              width: double.infinity,
              color: AppColors.background,
              child: Transform.translate(
                offset: const Offset(0, _countLift),
                child: Column(
                  children: const [
                    SpaceStudyCountWidget(),
                    SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: MyPageStudyRecordWidget(),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SettingSection(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  // ✅ "베젤 포함" 헤더 총 높이를 고정값 393으로 지정
  static const double _headerTotalHeight = 300.0;

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
    final statusBar = MediaQuery.of(context).padding.top; // 베젤(상단 안전영역) 높이
    const headerColor = AppColors.sub;

    // ✅ 실제 헤더 컨테이너(베젤 아래 영역) 높이 = 총 393 - 베젤
    final double headerBodyHeight = (_headerTotalHeight - statusBar).clamp(
      0.0,
      double.infinity,
    );

    return Scaffold(
      backgroundColor: headerColor, // ⬅️ 헤더색으로 배경 통일
      body: Column(
        children: [
          // ✅ 베젤 영역: 반드시 포함(색 동일)
          Container(height: statusBar, color: headerColor),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ───────── 헤더 영역 (베젤 제외분) ─────────
                  Container(
                    width: double.infinity,
                    height: headerBodyHeight, // ⬅️ 393 - statusBar
                    color: headerColor,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 16,
                          right: 16,
                          top: 230, // 기존 배치 유지 (필요시 여기만 미세 조정)
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

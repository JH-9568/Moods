// lib/features/my_page/my_page_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/features/my_page/setting/setting_widget.dart';

// 구성요소 위젯들
import 'package:moods/features/my_page/user_profile/user_profile_widget.dart';
import 'package:moods/features/my_page/space_study_count_widget.dart';
import 'package:moods/features/my_page/my_page_study_record_widget.dart';
import 'package:moods/features/my_page/setting/setting_widget.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ─────────────────────────────────────────────
              // 1) 상단 헤더 (연보라 배경 335px)
              //    내부에 UserProfileWidget 배치
              // ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                height: _headerHeight,
                color: const Color.fromRGBO(208, 215, 248, 1),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  // UserProfileWidget은 요청한 272x69 사이즈로 자체 렌더링됨
                  child: const UserProfileWidget(),
                ),
              ),

              // ─────────────────────────────────────────────
              // 2) 통계 카드(작은 컨테이너)를 헤더 아래로 겹치게 올림
              //    원하는 “얹혀 있는” 느낌을 위해 위로 34px 끌어올림
              // ─────────────────────────────────────────────
              Transform.translate(
                offset: const Offset(0, -34),
                child:
                    const SpaceStudyCountWidget(), // 329x69 / radius 8 / 가운데 흰색 라인
              ),

              // 겹친 만큼 아래 여백 보정
              const SizedBox(height: 10),

              // ─────────────────────────────────────────────
              // 3) 공부 기록 섹션 (마이페이지 전용 카드 + 리스트)
              // ─────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: MyPageStudyRecordWidget(),
              ),
              const SizedBox(height: 16),

              // ─────────────────────────────────────────────
              // 4) 설정 섹션 (로그아웃/탈퇴/버전)
              // ─────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SettingSection(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

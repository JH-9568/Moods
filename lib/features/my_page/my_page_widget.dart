import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle; // ✅ 디버그용 asset 체크

import 'package:moods/common/constants/colors.dart';
import 'package:moods/features/my_page/setting/setting_widget.dart';
import 'package:moods/features/my_page/widget/room_bg.dart';

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
  static const double _headerTotalHeight = 355.0;
  static const double _profileTop = 185.0;
  static const double _countLift = -42.0;

  @override
  void initState() {
    super.initState();

    // ✅ 디버그: JPEG 파일 존재 확인
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _debugCheckImageAsset();
      if (!mounted) return;
      ref.read(studyCountControllerProvider.notifier).loadIfNeeded();
      ref.read(studySpaceCountControllerProvider.notifier).loadIfNeeded();
    });
  }

  Future<void> _debugCheckImageAsset() async {
    const path = 'assets/fonts/icons/cafe.png'; // ✅ 실제 경로
    try {
      final data = await rootBundle.load(path);
      debugPrint(
        '✅ cafe.jpeg loaded successfully (${data.lengthInBytes} bytes)',
      );
    } catch (e) {
      debugPrint('❌ cafe.jpeg load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBar = MediaQuery.of(context).padding.top;
    const headerColor = AppColors.main;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // ───────── 헤더 ─────────
            Container(
              width: double.infinity,
              height: _headerTotalHeight + statusBar,
              color: Colors.transparent, // 배경은 painter가 칠함
              padding: EdgeInsets.only(top: statusBar),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -statusBar,
                    left: 0,
                    right: 0,
                    child: const RoomBg(height: 355),
                  ),

                  // 프로필 카드
                  const Positioned(
                    left: 16,
                    right: 16,
                    top: _profileTop,
                    child: UserProfileWidget(),
                  ),

                  // ────────────────── 카페 + 타원 그림자 (기존 그대로) ──────────────────
                  Positioned(
                    left: -23,
                    top: 0,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // 카페 하단 타원
                        Transform.translate(
                          offset: const Offset(-18, 162),
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 40,
                              sigmaY: 5,
                            ),
                            child: Opacity(
                              opacity: 1,
                              child: SizedBox(
                                width: 130,
                                height: 40,
                                child: ClipOval(
                                  child: const ColoredBox(
                                    color: AppColors.text_color1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 카페 PNG
                        Opacity(
                          opacity: 1,
                          child: Image.asset(
                            'assets/fonts/icons/cafe.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ────────────────── 스케이트 무스 + 타원 그림자 (신규) ──────────────────
                  // 디자인에 맞게 위치/크기는 살짝만 가늠치로 넣어두었어. 필요하면 수치만 조정!
                  Positioned(
                    left: 165, // ← 무스의 X 위치 (원하는 값으로 미세 조정)
                    top: 58, // ← 무스의 Y 위치
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // 무스 PNG
                        Opacity(
                          opacity: 1,
                          child: Image.asset(
                            'assets/fonts/icons/skate_moods.png',
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ───────────────────────────── Moods 텍스트 ─────────────────────────────
                  const Positioned(
                    right: 5,
                    top: 0,
                    child: Image(
                      image: AssetImage('assets/fonts/icons/my_page_moods.png'),
                      width: 120, // 원본 비율에 맞춰 조정 (필요 시 변경)
                      height: 35, // 원본 비율에 맞춰 조정
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            // ───────── 본문 영역 ─────────
            Container(
              width: double.infinity,
              color: AppColors.background,
              child: Transform.translate(
                offset: const Offset(0, _countLift - 60),
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

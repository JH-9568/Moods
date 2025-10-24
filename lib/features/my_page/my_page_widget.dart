import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle; // 디버그용 asset 체크

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

class _MyPageWidgetState extends ConsumerState<MyPageWidget>
    with TickerProviderStateMixin {
  static const double _headerTotalHeight = 355.0;
  static const double _profileTop = 185.0;
  static const double _countLift = -42.0;

  late final AnimationController _mooseCtrl;
  late final CurvedAnimation _mooseCurve;

  @override
  void initState() {
    super.initState();

    // 무스(스케이트) 이동 애니메이션
    _mooseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _mooseCurve = CurvedAnimation(parent: _mooseCtrl, curve: Curves.easeInOut);

    _mooseCtrl.addStatusListener((st) async {
      if (st == AnimationStatus.completed) {
        await Future.delayed(const Duration(milliseconds: 700)); // 집 앞에서 잠깐 정지
        _mooseCtrl.value = 0; // 오른쪽 바깥으로 리셋(순간 이동)
        _mooseCtrl.forward();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mooseCtrl.forward(); // 첫 시작

      // 디버그 asset 체크 + 통계 로딩
      _debugCheckImageAsset();
      ref.read(studyCountControllerProvider.notifier).loadIfNeeded();
      ref.read(studySpaceCountControllerProvider.notifier).loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _mooseCtrl.dispose();
    super.dispose();
  }

  Future<void> _debugCheckImageAsset() async {
    const path = 'assets/fonts/icons/cafe.png';
    try {
      final data = await rootBundle.load(path);
      debugPrint('✅ cafe.png loaded (${data.lengthInBytes}B)');
    } catch (e) {
      debugPrint('❌ cafe.png load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBar = MediaQuery.of(context).padding.top;

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
              color: Colors.transparent,
              padding: EdgeInsets.only(top: statusBar),
              // ⬇️ Stack 전체를 AnimatedBuilder로 감싸서 매 프레임 리빌드
              child: AnimatedBuilder(
                animation: _mooseCtrl,
                builder: (context, _) {
                  final screenW = MediaQuery.of(context).size.width;
                  final double startX = screenW + 160; // 오른쪽 화면 바깥
                  const double endX = 90.0;          // 집 앞(기존 left 값)
                  const double topY = 58.0;

                  // x 위치(직선 이동)
                  final double x =
                      lerpDouble(startX, endX, _mooseCurve.value)!;

                  // 살짝 위/아래 바운스(옵션)
                  final double bounce = lerpDouble(
                    -2,
                    2,
                    (1 - (2 * (_mooseCurve.value - 0.5)).abs()),
                  )!;

                  return Stack(
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

                      // ────────────────── 카페 + 타원 그림자 ──────────────────
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
                                imageFilter:
                                    ImageFilter.blur(sigmaX: 40, sigmaY: 5),
                                child: Opacity(
                                  opacity: 1,
                                  child: SizedBox(
                                    width: 130,
                                    height: 40,
                                    child: ClipOval(
                                      child:
                                          Container(color: AppColors.text_color1),
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

                      // ────────────────── 스케이트 무스(애니메이션) ──────────────────
                      Positioned(
                        left: x,               // ← 직계 자식으로 Positioned 배치 (에러 해결)
                        top: topY + bounce,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // 바닥 타원 그림자
                            Transform.translate(
                              offset: const Offset(0, 120),
                              child: ImageFiltered(
                                imageFilter:
                                    ImageFilter.blur(sigmaX: 30, sigmaY: 6),
                                child: Opacity(
                                  opacity: 0.35,
                                  child: SizedBox(
                                    width: 90,
                                    height: 26,
                                    child: ClipOval(
                                      child: Container(color: Colors.black),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // 무스 PNG
                            Image.asset(
                              'assets/fonts/icons/skate_moods.png',
                              width: 140,
                              height: 140,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),

                      // ───────────────────────────── Moods 텍스트 ─────────────────────────────
                      const Positioned(
                        right: 5,
                        top: 0,
                        child: Image(
                          image:
                              AssetImage('assets/fonts/icons/my_page_moods.png'),
                          width: 120,
                          height: 35,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ───────── 본문 영역 ─────────
            Container(
              width: double.infinity,
              color: AppColors.background,
              child: Transform.translate(
                offset: const Offset(0, _countLift - 60),
                child: const Column(
                  children: [
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

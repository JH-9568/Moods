// lib/features/home/widget/my_ranking/my_ranking_widget.dart
//
// ✅ 목적: 기능/값/로직은 변경하지 않고, 가독성과 유지보수성을 높이기 위한 리팩터링.
//    - 섹션/변수/메서드에 의미를 설명하는 주석 추가
//    - 그림자/간격/반지름 등 "디자인 조절 포인트"에 튜닝 가이드 주석 추가
//
// 🎨 [디자인 추가] 카드 하단에 '흰색 블러 + 흰색 그라데이션' 오버레이를 깔아
//    시간/횟수 텍스트 가독성 확보(높이/강도/그라데이션 스톱은 아래 상수로 조정)

import 'dart:math' as math;
import 'dart:ui' as ui; // ✅ blur를 위한 import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_empty.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_controller.dart';

/// -----------------------------
/// 🔧 하단 오버레이 튜닝 포인트
/// -----------------------------
/// - kBottomBlurHeight: 카드 하단에서부터 오버레이가 차지하는 높이(px)
/// - kBottomBlurSigma:  블러 강도(가로/세로 공통)
/// - kBottomFadeStops:  투명→흰색 그라데이션 전환 지점(0.0~1.0)
const double kBottomBlurHeight = 70; // ← 요청사항 기본값. 원하면 조정
const double kBottomBlurSigma = 6; // ← 6~12 권장

/// 홈 화면의 "나의 공간 랭킹" 카드(컨테이너 + 헤더 + 캐러셀)
class MyRankingWidget extends ConsumerWidget {
  const MyRankingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태/노티파이어
    final state = ref.watch(myRankingControllerProvider);
    final notifier = ref.read(myRankingControllerProvider.notifier);

    // 최초 1회 데이터 로드
    if (!state.loading && !state.loadedOnce && state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.loadIfNeeded();
      });
    }

    /// 공통 카드 래퍼 (크기/배경/라운드/패딩)
    Widget wrapCard(Widget child) {
      return Container(
        width: 361,
        constraints: const BoxConstraints(minHeight: 276),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );
    }

    /// 상단 헤더 (타이틀 + 서브텍스트)
    Widget header() => Padding(
      padding: const EdgeInsets.only(bottom: 2), // 헤더-본문 간격 조절 포인트
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('나의 공간 랭킹', style: AppTextStyles.title),
          Text(
            '내가 가장 많이 공부한 공간은?',
            style: AppTextStyles.small.copyWith(color: AppColors.text_color2),
          ),
        ],
      ),
    );

    // 로딩 초기 스켈레톤
    if (state.loading && !state.loadedOnce) {
      return wrapCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // 헤더
            Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: _HeaderStatic(),
            ),
            SizedBox(height: 4),
            _LoadingSkeleton(),
          ],
        ),
      );
    }

    // 에러/빈 데이터 처리
    if (state.error != null) return const RankingEmptyCard();
    if (state.items.isEmpty) return const RankingEmptyCard();

    // API 데이터 → 캐러셀 표시용 모델 (최대 5개)
    final items = state.items.take(5).map((e) {
      return RankingUiItem(
        title: e.spaceName,
        totalSeconds: e.myTotalRaw,
        sessions: e.myStudyCount,
        rank: e.userRank,
        imageUrl: (e.spaceImageUrl?.toString().trim().isEmpty ?? true)
            ? null
            : e.spaceImageUrl!.toString(),
      );
    }).toList();

    // 콘텐츠 구성: 헤더 + 캐러셀
    return wrapCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(),
          const SizedBox(height: 5), // 헤더-캐러셀 간격
          ArcRankingCarousel(
            items: items,
            itemSize: const Size(94.06, 146.97), // 🔧 카드 1장의 렌더 크기
            radius: 95, // 🔧 원호 반지름(좌우 퍼짐 정도)
            topInset: 40, // 🔧 캐러셀 상단 여백(위로/아래로)
          ),
        ],
      ),
    );
  }
}

/// 로딩 스켈레톤 전용 헤더(텍스트 값 동일, 위와 동일 동작)
class _HeaderStatic extends StatelessWidget {
  const _HeaderStatic();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('나의 공간 랭킹', style: AppTextStyles.title),
        Text(
          '내가 가장 많이 공부한 공간은?',
          style: AppTextStyles.small.copyWith(color: AppColors.text_color2),
        ),
      ],
    );
  }
}

/// 로딩 상태: 반응형 카드 스켈레톤 (overflow 방지)
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    // 카드 비율: 실제 카드와 동일(가로/세로)
    const double aspectRatio = 94.06 / 146.97;
    const int count = 4; // 로딩 때 보여줄 카드 개수
    const double gap = 12.0; // 카드 사이 간격
    const double radius = 12; // 모서리

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth; // 사용 가능한 전체 가로폭
        final cardW = (maxW - gap * (count - 1)) / count; // 남는 폭을 카드 개수만큼 균등 분배
        final cardH = cardW / aspectRatio;

        return SizedBox(
          height: cardH,
          child: Row(
            children: List.generate(count, (i) {
              return Padding(
                padding: EdgeInsets.only(right: i == count - 1 ? 0 : gap),
                child: Container(
                  width: cardW,
                  height: cardH,
                  decoration: BoxDecoration(
                    color:
                        Colors.white, // 스켈레톤 배경색(필요시 AppColors.border 등으로 변경)
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// 캐러셀이 사용하는 UI 모델
class RankingUiItem {
  final String title; // 공간명
  final double totalSeconds; // 총 공부 시간(초)
  final int sessions; // 공부 횟수
  final int rank; // 랭킹(없으면 0)
  final String? imageUrl; // 배경 이미지 URL (null이면 단색)

  const RankingUiItem({
    required this.title,
    required this.totalSeconds,
    required this.sessions,
    required this.rank,
    this.imageUrl,
  });

  Duration get total => Duration(seconds: totalSeconds.round());
}

///
/// ArcRankingCarousel
/// - 최대 5장 카드를 원호(arc) 형태로 좌우에 배치
/// - 드래그 시 ±1칸 스냅 이동 (부드러운 애니메이션)
/// - 마지막에서 넘기면 처음으로 순환
///
class ArcRankingCarousel extends StatefulWidget {
  final List<RankingUiItem> items; // 표시할 카드 목록(부모에서 최대 5개로 제한)
  final Size itemSize; // 🔧 카드 1장의 가로/세로
  final double radius; // 🔧 원호 반지름(값↑ → 카드 좌우 퍼짐↑)
  final double topInset; // 🔧 캐러셀 전체의 상단 오프셋(위로 당김/내림)
  final double viewTiltX; // 전체 캐러셀 X축 기울기(라디안, 음수면 아래에서 올려다봄)
  final double viewPerspective; // 원근감 강도 (0.001~0.003 권장)
  final double viewLift;
  final double verticalPerspective;
  final double centerDrop;

  const ArcRankingCarousel({
    super.key,
    required this.items,
    this.itemSize = const Size(140, 180),
    this.radius = 120,
    this.topInset = 8,
    this.viewTiltX = -0, // 약 -11.5°
    this.viewPerspective = 0.0, // 은은한 원근
    this.viewLift = 0, // 필요시 8~16 정도 넣어 살짝 들어올리기
    this.verticalPerspective = -10, // ← 12~24에서 취향대로
    this.centerDrop = 0, // ← 0~8 정도 추천
  });

  @override
  State<ArcRankingCarousel> createState() => _ArcRankingCarouselState();
}

class _ArcRankingCarouselState extends State<ArcRankingCarousel>
    with SingleTickerProviderStateMixin {
  // 원호의 기준 각도(드래그/스냅 시 갱신)
  double baseAngle = 0;

  // 스냅 애니메이션 컨트롤러/값
  late final AnimationController _ctrl;
  late Animation<double> _snapAnim;

  // 한 화면 최대 카드 수(로직 상한)
  static const int _visibleCount = 5;

  // 카드 간 각도(아이템 수에 따라 자동 균등 배치: 5개면 2π/5)
  double get slotAngle => (widget.items.isEmpty)
      ? 0
      : (2 * math.pi / widget.items.length.clamp(1, 5));

  // 중앙 카드 인덱스(스냅 대상)
  int currentIndex = 0;

  // 중앙 카드 식별(스타일 변경 등에 활용 가능)
  bool isCenter(int idx) => idx == currentIndex;

  // 🔧 드래그 민감도: 손가락 이동 픽셀 → 각도 변환 비율 (값↓ → 더 섬세)
  static const double _dragToAngle = 0.0045;

  // 드래그 임계값(한 칸 이동 판정)
  double _dragAccum = 0; // 누적 픽셀
  static const double _pixelsThreshold = 24; // 느린 드래그 시 이동 임계
  static const double _velocityThreshold = 200; // 빠른 스와이프 속도 임계(px/s)

  // 안전 setState
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    // ❗ 컨트롤러는 initState에서 생성 (필드 초기화 X)
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _snapAnim = const AlwaysStoppedAnimation<double>(0);
  }

  @override
  void dispose() {
    // ❗ dispose에서는 context 의존 금지 & 컨트롤러만 정리
    _ctrl.dispose();
    super.dispose();
  }

  // 드래그 시작: 누적 초기화 & 진행 중 애니 정지
  void _onDragStart(DragStartDetails d) {
    _dragAccum = 0;
    _ctrl.stop();
  }

  // 드래그 중: baseAngle 업데이트(좌우 이동)
  void _onDragUpdate(DragUpdateDetails d) {
    _safeSetState(() {
      final delta = d.delta.dx;
      baseAngle += delta * _dragToAngle; // 픽셀 → 각도 변환
      baseAngle = _normalize(baseAngle); // 0~2π 범위로 정규화
      _dragAccum += delta; // 누적 픽셀
    });
  }

  // 드래그 끝: 속도/누적 값으로 방향 결정 → 정확히 1칸 스냅
  void _onDragEnd(DragEndDetails d) {
    final vx = d.velocity.pixelsPerSecond.dx;

    int dir = 0;
    if (vx.abs() > _velocityThreshold) {
      dir = vx.sign.toInt(); // 빠른 스와이프
    } else if (_dragAccum.abs() > _pixelsThreshold) {
      dir = _dragAccum.sign.toInt(); // 느린 드래그
    }

    if (dir != 0) {
      currentIndex = (currentIndex + dir) % widget.items.length;
      if (currentIndex < 0) currentIndex += widget.items.length;
    }

    // 스냅 목표 각도
    final target = currentIndex * slotAngle;

    // 부드럽게 baseAngle → target 으로 보간
    _ctrl.stop();
    _snapAnim =
        Tween<double>(
            begin: 0,
            end: _shortestDelta(baseAngle, target), // 최단 각도 경로
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_ctrl)
          ..addListener(() {
            // 애니메이션 중 프레임마다 다시 그리기
            _safeSetState(() {});
          })
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              _safeSetState(() {
                baseAngle = _normalize(target);
                _snapAnim = const AlwaysStoppedAnimation(0);
              });
            }
          });

    _ctrl.forward(from: 0);
  }

  // 애니메이션 적용된 현재 각도
  double get animatedBaseAngle => baseAngle + _snapAnim.value;

  @override
  Widget build(BuildContext context) {
    final raw = widget.items;
    final int count = math.min(_visibleCount, raw.length);
    final items = raw.take(count).toList(growable: false);

    // 캐러셀 전체 높이 (상단 여백 + 카드 높이 + 여유)
    final double carouselHeight = widget.itemSize.height + widget.topInset + 15;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double localWidth = constraints.maxWidth;

        // 각 카드의 배치/시각 효과 파라미터 계산
        final List<_Placed> placed = [];
        for (int i = 0; i < items.length; i++) {
          final double a = animatedBaseAngle + i * slotAngle; // i번째 카드 각도

          // 원호 좌표와 깊이(0~1)
          final double x = widget.radius * math.sin(a); // 가로 좌표
          final double z = (math.cos(a) + 1) / 2; // 깊이: -1~1 → 0~1
          final double y =
              -widget.verticalPerspective * (1 - z) + widget.centerDrop;

          // 🔧 깊이 z 기반 시각 효과(보간 범위 조절로 느낌 변경 가능)
          final double scale = _lerp(0.72, 1.1, z); // 크기
          final double opacity = _lerp(0.22, 1.0, z); // 투명도
          final double elevation = _lerp(0, 16, z); // (미사용) 그림자 세기

          placed.add(
            _Placed(
              index: i,
              angle: a,
              x: x,
              y: y,
              z: z,
              scale: scale,
              opacity: opacity,
              elevation: elevation,
              tilt: 0, // 기울기(현재 0)
            ),
          );
        }

        // 깊이(z) 오름차순 → 뒤에서 앞으로 겹치도록
        placed.sort((a, b) => a.z.compareTo(b.z));

        return GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: SizedBox(
            height: carouselHeight,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                for (final p in placed)
                  Positioned(
                    // 가로 중앙 기준으로 x 오프셋
                    left: (localWidth / 2) + p.x - (widget.itemSize.width / 2),
                    // 상단에서 topInset 만큼만 띄워 배치
                    top: widget.topInset + p.y,
                    child: Opacity(
                      opacity: p.opacity,
                      child: Transform.rotate(
                        angle: p.tilt,
                        child: Transform.scale(
                          scale: p.scale,
                          alignment: Alignment.center,
                          child: _RankingCard(
                            item: items[p.index],
                            size: widget.itemSize,
                            elevation: p.elevation, // (현재 UI에선 미사용)
                            isCenter:
                                (_wrapPi(p.angle)).abs() < slotAngle * 0.28,
                            // 랭크 텍스트(서버 rank>0이면 사용, 아니면 index+1)
                            rankText: (items[p.index].rank > 0)
                                ? '${items[p.index].rank}등'
                                : '${p.index + 1}등',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----- 수학 유틸 -----

  /// 0 ~ 2π 범위로 정규화
  static double _normalize(double a) {
    final twoPi = math.pi * 2;
    a %= twoPi;
    if (a < 0) a += twoPi;
    return a;
  }

  /// -π ~ π 범위로 변환(두 각의 최단 차 계산용)
  static double _wrapPi(double a) {
    final twoPi = math.pi * 2;
    a = (a + math.pi) % twoPi;
    if (a < 0) a += twoPi;
    return a - math.pi;
  }

  /// base → target 최단 각도 차(부호 포함)
  static double _shortestDelta(double base, double target) {
    return _wrapPi(target - base);
  }

  /// 선형 보간
  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

/// Stack 배치를 위한 카드 렌더 파라미터 묶음
class _Placed {
  final int index; // items 인덱스
  final double angle; // 현재 각도(라디안)
  final double x, y; // 위치 오프셋
  final double z; // 깊이(0~1)
  final double scale; // 크기(깊이 기반)
  final double opacity; // 투명도(깊이 기반)
  final double elevation; // 그림자 세기(깊이 기반, 현재 미사용)
  final double tilt; // 기울기(현재 0)

  const _Placed({
    required this.index,
    required this.angle,
    required this.x,
    required this.y,
    required this.z,
    required this.scale,
    required this.opacity,
    required this.elevation,
    required this.tilt,
  });
}

/// 개별 카드 UI (배경 이미지/왕관/텍스트/지표)
class _RankingCard extends StatelessWidget {
  final RankingUiItem item;
  final Size size;
  final double elevation; // Note: 현재 BoxShadow로 대체, 변수는 유지만 함
  final bool isCenter;
  final String rankText;

  const _RankingCard({
    super.key,
    required this.item,
    required this.size,
    required this.elevation,
    required this.isCenter,
    required this.rankText,
  });

  /// Duration → "N시간 M분" 간단 포맷
  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}시간 ${m}분';
  }

  @override
  Widget build(BuildContext context) {
    final bg = item.imageUrl;

    return Material(
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12), // Material 레벨 라운드
      child: Container(
        width: size.width,
        height: size.height,
        clipBehavior: Clip.none, // ✅ 라운드가 자식에도 적용되도록
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none, // 왕관이 카드 밖으로 나올 수 있게
          children: [
            // (옵션) 전체 오버레이/그라데이션이 필요할 때 쓸 자리
            // ⬇️ Stack(children: [ ... ]) 맨 앞에 넣기
            if (bg != null)
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (Rect rect) {
                    const double fadePx = 70; // ← 원하는 페이드 높이(px)
                    final double start = ((rect.height - fadePx) / rect.height)
                        .clamp(0.0, 1.0);

                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      // 위쪽은 완전 보이게(검정) 유지, 'start' 지점부터 아래로 자연 페이드
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, start, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn, // 이미지 알파를 그라데이션으로 마스크
                  child: Image.network(
                    bg!,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),

            // ✅ 1등 카드 상단 중앙에 왕관 아이콘 표시
            if (rankText.startsWith('1'))
              Positioned(
                top: -14, // 🔧 왕관이 테두리를 살짝 넘도록 음수(top) 사용
                left: 0,
                right: 0,
                child: Center(
                  child: SvgPicture.asset(
                    "assets/fonts/icons/crown.svg",
                    width: 21, // 🔧 왕관 크기
                    height: 21, // 🔧 왕관 크기
                  ),
                ),
              ),

            // 랭킹 텍스트(카드 상단부)
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  rankText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ),

            // 공간명
            Positioned(
              bottom: 40,
              left: 6,
              right: 6,
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),

            // 하단 지표(시간/횟수) — 오버레이 위에 올라가므로 가독성↑
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 시간
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '시간',
                        style: TextStyle(
                          color: Color.fromRGBO(38, 38, 38, 1),
                          fontWeight: FontWeight.w600,
                          fontSize: 8.4,
                        ),
                      ),
                      Text(
                        _formatDuration(item.total),
                        style: TextStyle(
                          color: AppColors.text_color1,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 횟수
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '횟수',
                        style: TextStyle(
                          color: Color.fromRGBO(38, 38, 38, 1),
                          fontWeight: FontWeight.w600,
                          fontSize: 8.4,
                        ),
                      ),
                      Text(
                        '${item.sessions}회',
                        style: TextStyle(
                          color: AppColors.text_color1,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.6,
                        ),
                      ),
                    ],
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

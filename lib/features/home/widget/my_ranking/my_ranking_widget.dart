// lib/features/home/widget/my_ranking/my_ranking_widget.dart
//
// ✅ 목적: 기능/값/로직은 변경하지 않고, 가독성과 유지보수성을 높이기 위한 리팩터링.
//    - 섹션/변수/메서드에 의미를 설명하는 주석 추가
//    - 그림자/간격/반지름 등 "디자인 조절 포인트"에 튜닝 가이드 주석 추가
//
// 🎨 [디자인 수정] 카드 전체에 위→아래로 흰색 그라데이션 (0% → 100%) 적용

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_empty.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_controller.dart';

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
      padding: const EdgeInsets.only(bottom: 2),
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
          const SizedBox(height: 5),
          ArcRankingCarousel(
            items: items,
            itemSize: const Size(94.06, 146.97),
            radius: 95,
            topInset: 40,
          ),
        ],
      ),
    );
  }
}

/// 로딩 스켈레톤 전용 헤더
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

/// 로딩 상태: 반응형 카드 스켈레톤
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    const double aspectRatio = 94.06 / 146.97;
    const int count = 4;
    const double gap = 12.0;
    const double radius = 12;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final cardW = (maxW - gap * (count - 1)) / count;
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
                    color: Colors.white,
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
  final String title;
  final double totalSeconds;
  final int sessions;
  final int rank;
  final String? imageUrl;

  const RankingUiItem({
    required this.title,
    required this.totalSeconds,
    required this.sessions,
    required this.rank,
    this.imageUrl,
  });

  Duration get total => Duration(seconds: totalSeconds.round());
}

/// ArcRankingCarousel
class ArcRankingCarousel extends StatefulWidget {
  final List<RankingUiItem> items;
  final Size itemSize;
  final double radius;
  final double topInset;
  final double viewTiltX;
  final double viewPerspective;
  final double viewLift;
  final double verticalPerspective;
  final double centerDrop;

  const ArcRankingCarousel({
    super.key,
    required this.items,
    this.itemSize = const Size(140, 180),
    this.radius = 120,
    this.topInset = 8,
    this.viewTiltX = -0,
    this.viewPerspective = 0.0,
    this.viewLift = 0,
    this.verticalPerspective = -10,
    this.centerDrop = 0,
  });

  @override
  State<ArcRankingCarousel> createState() => _ArcRankingCarouselState();
}

class _ArcRankingCarouselState extends State<ArcRankingCarousel>
    with SingleTickerProviderStateMixin {
  double baseAngle = 0;
  late final AnimationController _ctrl;
  late Animation<double> _snapAnim;
  static const int _visibleCount = 5;

  double get slotAngle => (widget.items.isEmpty)
      ? 0
      : (2 * math.pi / widget.items.length.clamp(1, 5));

  int currentIndex = 0;
  bool isCenter(int idx) => idx == currentIndex;
  static const double _dragToAngle = 0.0045;
  double _dragAccum = 0;
  static const double _pixelsThreshold = 24;
  static const double _velocityThreshold = 200;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _snapAnim = const AlwaysStoppedAnimation<double>(0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails d) {
    _dragAccum = 0;
    _ctrl.stop();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _safeSetState(() {
      final delta = d.delta.dx;
      baseAngle += delta * _dragToAngle;
      baseAngle = _normalize(baseAngle);
      _dragAccum += delta;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final vx = d.velocity.pixelsPerSecond.dx;

    int dir = 0;
    if (vx.abs() > _velocityThreshold) {
      dir = vx.sign.toInt();
    } else if (_dragAccum.abs() > _pixelsThreshold) {
      dir = _dragAccum.sign.toInt();
    }

    if (dir != 0) {
      currentIndex = (currentIndex + dir) % widget.items.length;
      if (currentIndex < 0) currentIndex += widget.items.length;
    }

    final target = currentIndex * slotAngle;

    _ctrl.stop();
    _snapAnim =
        Tween<double>(
            begin: 0,
            end: _shortestDelta(baseAngle, target),
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_ctrl)
          ..addListener(() {
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

  double get animatedBaseAngle => baseAngle + _snapAnim.value;

  @override
  Widget build(BuildContext context) {
    final raw = widget.items;
    final int count = math.min(_visibleCount, raw.length);
    final items = raw.take(count).toList(growable: false);

    final double carouselHeight = widget.itemSize.height + widget.topInset + 15;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double localWidth = constraints.maxWidth;

        final List<_Placed> placed = [];
        for (int i = 0; i < items.length; i++) {
          final double a = animatedBaseAngle + i * slotAngle;

          final double x = widget.radius * math.sin(a);
          final double z = (math.cos(a) + 1) / 2;
          final double y =
              -widget.verticalPerspective * (1 - z) + widget.centerDrop;

          final double scale = _lerp(0.72, 1.1, z);
          final double opacity = _lerp(0.22, 1.0, z);
          final double elevation = _lerp(0, 16, z);

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
              tilt: 0,
            ),
          );
        }

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
                    left: (localWidth / 2) + p.x - (widget.itemSize.width / 2),
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
                            elevation: p.elevation,
                            isCenter:
                                (_wrapPi(p.angle)).abs() < slotAngle * 0.28,
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

  static double _normalize(double a) {
    final twoPi = math.pi * 2;
    a %= twoPi;
    if (a < 0) a += twoPi;
    return a;
  }

  static double _wrapPi(double a) {
    final twoPi = math.pi * 2;
    a = (a + math.pi) % twoPi;
    if (a < 0) a += twoPi;
    return a - math.pi;
  }

  static double _shortestDelta(double base, double target) {
    return _wrapPi(target - base);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _Placed {
  final int index;
  final double angle;
  final double x, y;
  final double z;
  final double scale;
  final double opacity;
  final double elevation;
  final double tilt;

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
  final double elevation;
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size.width,
        height: size.height,
        clipBehavior: Clip.none,
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
          clipBehavior: Clip.none,
          children: [
            // 배경 이미지
            if (bg != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    bg,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),

            // 🎨 전체 흰색 그라데이션 오버레이 (위 0% → 아래 100%)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.0), // 맨 위 0%
                        Colors.white.withOpacity(1.0), // 맨 아래 100%
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 왕관 (1등만)
            if (rankText.startsWith('1'))
              Positioned(
                top: -14,
                left: 0,
                right: 0,
                child: Center(
                  child: SvgPicture.asset(
                    "assets/fonts/icons/crown.svg",
                    width: 21,
                    height: 21,
                  ),
                ),
              ),

            // 랭킹 텍스트
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

            // 하단 지표(시간/횟수)
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
                        style: const TextStyle(
                          color: Colors.black,
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
                        style: const TextStyle(
                          color: Colors.black,
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

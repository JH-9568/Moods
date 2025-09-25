// lib/features/home/widget/my_ranking/my_ranking_widget.dart
//
// ✅ 목적: 현재 동작은 유지하면서 가독성과 유지보수성을 높이기 위해
//         섹션/변수/메서드별 주석을 보강한 리팩터링 버전입니다.
//         (기능/값/로직은 변경하지 않음)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart'; // ✅ SVG 추가

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_empty.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_controller.dart';

/// 홈 화면의 "나의 공간 랭킹" 카드 전체 컨테이너.
class MyRankingWidget extends ConsumerWidget {
  const MyRankingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRankingControllerProvider);
    final notifier = ref.read(myRankingControllerProvider.notifier);

    if (!state.loading && !state.loadedOnce && state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.loadIfNeeded();
      });
    }

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

    Widget header() => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('나의 공간 랭킹', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            '내가 가장 많이 공부한 공간은?',
            style: AppTextStyles.small.copyWith(color: AppColors.text_color2),
          ),
        ],
      ),
    );

    if (state.loading && !state.loadedOnce) {
      return wrapCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header(),
            const SizedBox(height: 4),
            const _LoadingSkeleton(),
          ],
        ),
      );
    }

    if (state.error != null) return const RankingEmptyCard();
    if (state.items.isEmpty) return const RankingEmptyCard();

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

    return wrapCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(),
          const SizedBox(height: 0),
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

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (_) {
          return Container(
            width: 140,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
      ),
    );
  }
}

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

class ArcRankingCarousel extends StatefulWidget {
  final List<RankingUiItem> items;
  final Size itemSize;
  final double radius;
  final double topInset;

  const ArcRankingCarousel({
    super.key,
    required this.items,
    this.itemSize = const Size(140, 180),
    this.radius = 120,
    this.topInset = 8,
  });

  @override
  State<ArcRankingCarousel> createState() => _ArcRankingCarouselState();
}

class _ArcRankingCarouselState extends State<ArcRankingCarousel>
    with SingleTickerProviderStateMixin {
  double baseAngle = 0;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late Animation<double> _snapAnim = const AlwaysStoppedAnimation<double>(0);

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
    setState(() {
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
          ..addListener(() => setState(() {}))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              setState(() {
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
          const double y = 0;
          final double z = (math.cos(a) + 1) / 2;

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
  final double angle, x, y, z, scale, opacity, elevation, tilt;
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

/// 개별 카드 UI
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          image: bg == null
              ? null
              : DecorationImage(image: NetworkImage(bg), fit: BoxFit.cover),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // ✅ 왕관 아이콘: 1등 카드일 때만 표시
            if (rankText.startsWith('1'))
              Positioned(
                top: -16, // 카드 상단과의 간격
                left: 0,
                right: 0,
                child: Center(
                  child: SvgPicture.asset(
                    "assets/fonts/icons/crown.svg",
                    width: 20,
                    height: 24,
                  ),
                ),
              ),
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
                  fontSize: 12,
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

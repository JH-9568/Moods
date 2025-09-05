// lib/features/home/widget/my_ranking/my_ranking_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_empty.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_controller.dart';

/// 홈에서 바로 쓸 수 있는 블록 위젯 (섹션 역할 + 본문 UI + 빈 상태 처리까지)
/// - 컨트롤러 상태를 보고: 로딩 → 로딩UI, 에러/빈 → Empty, 데이터 → 캐러셀
class MyRankingWidget extends ConsumerWidget {
  const MyRankingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRankingControllerProvider);
    final notifier = ref.read(myRankingControllerProvider.notifier);

    // 최초 진입 시 자동 로드(이미 로드 중/완료면 무시)
    if (!state.loading && !state.loadedOnce && state.error == null) {
      // 마운트 타이밍 보정
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.loadIfNeeded(); // JWT는 providers에서 자동 주입
      });
    }

    // 카드 컨테이너(섹션) 공통 래핑
    Widget wrapCard(Widget child) {
      return Container(
        width: 361,
        constraints: const BoxConstraints(minHeight: 276),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.border, // Main/2
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );
    }

    // 헤더 타이틀
    Widget header() => Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
      // 첫 로딩 스켈레톤
      return wrapCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [header(), const SizedBox(height: 8), _LoadingSkeleton()],
        ),
      );
    }

    if (state.error != null) {
      // 에러 → Empty UI로 단순 대체(필요하면 재시도 버튼 추가 가능)
      return const RankingEmptyCard();
    }

    if (state.items.isEmpty) {
      // 데이터 없음 → Empty UI
      return const RankingEmptyCard();
    }

    // 데이터가 있을 때: 상위 5개만 사용
    final items = state.items.take(5).map((e) {
      return RankingUiItem(
        title: e.spaceName,
        totalMinutes: (e.myTotalMinutes is num)
            ? (e.myTotalMinutes as num).toDouble()
            : double.tryParse('${e.myTotalMinutes}') ?? 0.0,
        sessions: e.myStudyCount,
        rank: e.userRank,
        imageUrl: (e.spaceImageUrl?.toString().trim().isEmpty ?? true)
            ? null
            : e.spaceImageUrl!.toString(),
      );
    }).toList();

    // ... 위 생략
    return wrapCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(),
          const SizedBox(height: 2),
          ArcRankingCarousel(
            items: items,
            itemSize: const Size(94.06, 146.97), // 👈 카드 폭/높이 고정
            radius: 90,
          ),
        ],
      ),
    );
  }
}

/// 로딩 시 간단한 스켈레톤
class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200, // roughly space left under the header
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

/// 캐러셀로 넘길 UI용 모델(컨트롤러 모델을 단순 변환)
class RankingUiItem {
  final String title;
  final double totalMinutes;
  final int sessions;
  final int rank; // API 순위 그대로 사용
  final String? imageUrl;
  const RankingUiItem({
    required this.title,
    required this.totalMinutes,
    required this.sessions,
    required this.rank,
    this.imageUrl,
  });

  Duration get total => Duration(minutes: totalMinutes.round());
}

/// 원호/심도 캐러셀
class ArcRankingCarousel extends StatefulWidget {
  /// 누적시간 내림차순(=1등이 먼저) 정렬된 5개 이내 리스트라고 가정
  final List<RankingUiItem> items;

  /// 카드 크기
  final Size itemSize;

  /// 반경(원호의 반지름)
  final double radius;

  const ArcRankingCarousel({
    super.key,
    required this.items,
    this.itemSize = const Size(140, 180),
    this.radius = 120,
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

  static const int _visibleCount = 5; // 최대 5개
  double get slotAngle => math.pi / 6; // 간격 각도
  static const double _dragToAngle = 0.009; // 드래그 민감도

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      baseAngle += d.delta.dx * _dragToAngle;
      baseAngle = _normalize(baseAngle);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final nearest = (baseAngle / slotAngle).roundToDouble() * slotAngle;
    final delta = _shortestDelta(baseAngle, nearest);

    _ctrl.stop();
    _snapAnim =
        Tween<double>(
            begin: 0,
            end: delta,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_ctrl)
          ..addListener(() => setState(() {}))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              setState(() {
                baseAngle = _normalize(baseAngle + delta);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final double localWidth = constraints.maxWidth;
        final List<_Placed> placed = [];

        for (int i = 0; i < items.length; i++) {
          final double a = animatedBaseAngle + i * slotAngle;

          final double x = widget.radius * math.sin(a);
          final double y = 0;
          final double z = (math.cos(a) + 1) / 2; // 0..1

          final double scale = _lerp(0.72, 1.1, z);
          final double opacity = _lerp(0.22, 1.0, z);
          final double elevation = _lerp(0, 16, z);
          final double tilt = 0;
          final double lift = 0;

          placed.add(
            _Placed(
              index: i,
              angle: a,
              x: x,
              y: y + lift,
              z: z,
              scale: scale,
              opacity: opacity,
              elevation: elevation,
              tilt: tilt,
            ),
          );
        }

        placed.sort((a, b) => a.z.compareTo(b.z));

        return GestureDetector(
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: SizedBox(
            height: widget.itemSize.height + widget.radius * 0.9,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (final p in placed)
                  Positioned(
                    left: (localWidth / 2) + p.x - (widget.itemSize.width / 2),
                    top: (widget.itemSize.height / 2) + p.y,
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
                            isCenter: _isCenter(p.angle),
                            // API의 순위 그대로 보여주되, 없으면 포지션+1
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

  bool _isCenter(double a) => (_wrapPi(a)).abs() < slotAngle * 0.28;

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

/// 실제 카드 UI
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
      elevation: elevation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          image: bg == null
              ? null
              : DecorationImage(image: NetworkImage(bg), fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            // 하단 가독성 보정용 그라데이션
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.10), // 상단도 약간 어둡게
                      Colors.black.withOpacity(0.70),
                    ],
                  ),
                ),
              ),
            ),

            // 1) 상단 중앙: 등수
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  rankText, // 예: "1등"
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 20, // 카드 작아졌으니 살짝 줄임
                  ),
                ),
              ),
            ),

            // 2) 등수 아래 중앙: 지점명
            Positioned(
              top: 36, // 등수 아래로 적당히
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

            // 3) 하단: 시간 / 4) 하단: 횟수
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
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _formatDuration(item.total),
                        style: TextStyle(
                          color: AppColors.main, // 네 앱 메인컬러
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
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
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${item.sessions}회',
                        style: TextStyle(
                          color: AppColors.main,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
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

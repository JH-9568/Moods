import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 랭킹 아이템(이름/총시간 등 원하는 데이터로 바꿔도 됨)
class RankingItem {
  final String title;
  final Duration total; // 누적 공부시간
  const RankingItem(this.title, this.total);
}

/// 원호/심도 캐러셀
class ArcRankingCarousel extends StatefulWidget {
  /// 누적시간 내림차순으로 들어온 리스트라고 가정(1등=0번)
  final List<RankingItem> items;

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
  // 현재 기준 각도(라디안). center = 0에 1등이 오도록 설계
  double baseAngle = 0;

  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
  late Animation<double> _snapAnim = AlwaysStoppedAnimation<double>(0); // 스냅 애니메이션 보간용

  // 보여줄 개수는 항상 5개
  static const int _visibleCount = 5;

  // 한 슬롯(등수) 간격 각도: 반원에 (5-1)=4 간격으로 배치 → π/4
  double get slotAngle => math.pi / 6;

  // 애니메이션 중이면 보간, 아니면 현재 값
  double get animatedBaseAngle => baseAngle + (_snapAnim.value);

  // 드래그 민감도(화면 px 대비 각도로 환산)
  static const double _dragToAngle = 0.009;

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
    // 현재 각도를 가장 가까운 슬롯 정렬로 스냅
    final nearest = (baseAngle / slotAngle).roundToDouble() * slotAngle;
    final delta = _shortestDelta(baseAngle, nearest);

    _ctrl.stop();
    _snapAnim = Tween<double>(begin: 0, end: delta)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_ctrl)
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

  @override
  Widget build(BuildContext context) {
    // 정확히 5개만 사용
    final raw = widget.items;
    final int count = math.min(_visibleCount, raw.length);
    final items = raw.take(count).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double localWidth = constraints.maxWidth;
        final List<_Placed> placed = [];

        // 각 아이템의 "절대 각도" 계산 (1등=0, 2등=+slot, 3등=+2slot ...)
        // 그 값에 animatedBaseAngle을 더해 전체 회전
        for (int i = 0; i < items.length; i++) {
          final double a = animatedBaseAngle + i * slotAngle;

          // x: 좌우, y: 위아래(원호), z: 깊이(정면=scale↑, opacity↑)
          final double x = widget.radius * math.sin(a);
          final double y = 0; // 정면 시점: 수직 이동 제거
          final double z = (math.cos(a) + 1) / 2; // 0..1 (뒤..앞)

          // 깊이감: 스케일/알파/그림자/회전/verticalLift 모두 z로 보간
          final double scale = _lerp(0.72, 1.1, z);            // 크기 차이를 더 키움
          final double opacity = _lerp(0.22, 1.0, z);           // 뒤쪽은 더 흐리게
          final double elevation = _lerp(0, 16, z);             // 그림자 강도
          final double tilt = 0;
          final double lift = 0;       // 앞쪽은 살짝 내려오게

          placed.add(_Placed(
            index: i,
            angle: a,
            x: x,
            y: y + lift,
            z: z,
            scale: scale,
            opacity: opacity,
            elevation: elevation,
            tilt: tilt,
          ));
        }

        // z(깊이) 오름차순으로 먼저 그려서 앞(큰 것)이 마지막에 그려지게
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
                // (중앙 배경 원 제거됨)
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
                            rankText: '${p.index + 1}등',
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
    // 0..2π 로 정규화
    final twoPi = math.pi * 2;
    a %= twoPi;
    if (a < 0) a += twoPi;
    return a;
  }

  // -π..π 범위로 감싼 각도
  static double _wrapPi(double a) {
    final twoPi = math.pi * 2;
    a = (a + math.pi) % twoPi;
    if (a < 0) a += twoPi;
    return a - math.pi;
  }

  // base→target 으로 가는 가장 짧은 각도 변화량
  static double _shortestDelta(double base, double target) {
    final a = _wrapPi(target - base);
    return a;
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

/// 실제 카드 UI (임시 예시)
class _RankingCard extends StatelessWidget {
  final RankingItem item;
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

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // 하단 그라데이션
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.70),
                    ],
                  ),
                ),
              ),
            ),
            // 텍스트
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('${item.total.inHours}시간 ${item.total.inMinutes % 60}분',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                ],
              ),
            ),
            // 중앙 카드에 랭크 배지 (선택)
            if (isCenter)
              Positioned(
                top: -6,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(rankText,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
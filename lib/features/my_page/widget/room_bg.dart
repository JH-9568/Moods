// lib/features/my_page/widgets/room_bg.dart
import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';

class RoomBg extends StatelessWidget {
  const RoomBg({
    super.key,
    this.height = 355,
    this.base = const Color(0xFF7E6356), // 전체 바탕(혹은 미세한 깔림용)
    this.leftTint = AppColors.main, // 왼쪽 벽
    this.rightTint = AppColors.room_color1, // 오른쪽 벽
    this.floorTint = AppColors.room_color2, // 바닥
  });

  final double height;
  final Color base, leftTint, rightTint, floorTint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _RoomBgPainter(
          base: base,
          leftTint: leftTint,
          rightTint: rightTint,
          floorTint: floorTint,
        ),
      ),
    );
  }
}

class _RoomBgPainter extends CustomPainter {
  _RoomBgPainter({
    required this.base,
    required this.leftTint,
    required this.rightTint,
    required this.floorTint,
  });

  final Color base, leftTint, rightTint, floorTint;

  @override
  void paint(Canvas canvas, Size size) {
    // 피그마 기준 크기
    const figmaW = 393.0;
    const figmaH = 355.0;

    // 현재 위젯 크기에 맞춰 스케일
    final sx = size.width / figmaW;
    final sy = size.height / figmaH;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    // 0) 전체 바탕
    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    // 1) 왼쪽 벽 (사다리꼴) — 좌표: A(0,0) B(144,0) C(144,173) D(0,216)
    final leftWall = Path()
      ..moveTo(p(0, 0).dx, p(0, 0).dy)
      ..lineTo(p(144, 0).dx, p(144, 0).dy)
      ..lineTo(p(144, 173).dx, p(144, 173).dy)
      ..lineTo(p(0, 216).dx, p(0, 216).dy)
      ..close();
    canvas.drawPath(leftWall, Paint()..color = leftTint);

    // 2) 오른쪽 벽 — 좌표: E(144,0) F(393,0) G(393,196) H(144,173)
    final rightWall = Path()
      ..moveTo(p(144, 0).dx, p(144, 0).dy)
      ..lineTo(p(393, 0).dx, p(393, 0).dy)
      ..lineTo(p(393, 196).dx, p(393, 196).dy)
      ..lineTo(p(144, 173).dx, p(144, 173).dy)
      ..close();
    canvas.drawPath(rightWall, Paint()..color = rightTint);

    // 3) 바닥 — 좌표: I(0,216) J(144,173) K(393,196) L(393,355) M(0,355)
    final floor = Path()
      ..moveTo(p(0, 216).dx, p(0, 216).dy)
      ..lineTo(p(144, 173).dx, p(144, 173).dy)
      ..lineTo(p(393, 196).dx, p(393, 196).dy)
      ..lineTo(p(393, 355).dx, p(393, 355).dy)
      ..lineTo(p(0, 355).dx, p(0, 355).dy)
      ..close();
    canvas.drawPath(floor, Paint()..color = floorTint);
  }

  @override
  bool shouldRepaint(covariant _RoomBgPainter old) =>
      base != old.base ||
      leftTint != old.leftTint ||
      rightTint != old.rightTint ||
      floorTint != old.floorTint;
}

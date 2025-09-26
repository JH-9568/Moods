// lib/features/record/view/record_finalize_step1.dart
// ============================================================================
// Step 1 — 요약 / 목표 / 공간 무드 (정리 버전: 기능·디자인·이름 100% 동일)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:moods/features/record/controller/record_controller.dart';
import 'package:moods/features/record/widget/widget.dart';
import 'record_finalize_step2.dart' show FinalizeStep2Screen;

// ============================================================================
// 1) Layout Tokens
// ============================================================================
const double kHeaderIconSize   = 30;   // 체크 아이콘 박스 크기
const double kHeaderIconStroke = 4.0;  // 체크 선 굵기 (두껍게!)
const double kHeaderGap        = 8;    // 체크와 '오늘 공부' 텍스트 간격
const double kTitleToCardGap   = 24;   // 제목 아래 카드까지 간격
const double kBodyTopPadding   = 28;   // 앱바와 헤더 사이(조금 더 아래로)

// ============================================================================
// 2) Color & Style Tokens
// ============================================================================
class C {
  static const bg           = Color(0xFFE8EBF8);
  static const headerBg     = Color(0xFFA7B3F1);
  static const surface      = Colors.white;
  static const chipStroke   = Color(0xFFE5E7F4);
  static const primarySoft  = Color(0xFFA7B3F1);
  static const primaryDeep  = Color(0xFFA7B3F1);
  static const textMain     = Color(0xFF111318);
  static const textSub      = Color(0xFF3B3F55);
  static const textWeak     = Color(0xFFB7BED6);
  static const disabledFill = Color(0xFFF0F2F8);
  static const disabledTxt  = Color(0xFFB9C0D6);
}

class S {
  static const r8  = Radius.circular(8);
  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);
}

// ============================================================================
// 3) (Optional) 라벨/태그 상수  *원본 그대로 유지*
// ============================================================================
const MOOD_TAGS = <String>[
  '트렌디한','감성적인','개방적인','자연친화적인','컨셉있는','활기찬','아늑한','조용한',
];

// ============================================================================
// 4) Helpers (원본 로직 그대로)
// ============================================================================
String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String two(int v) => v.toString().padLeft(2, '0');
String fmtDur(Duration d) =>
    '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';

// ============================================================================
// 5) Entry (풀스크린 네비 시작점)  *원본 그대로*
// ============================================================================
Future<void> showRecordFinalizeFlow(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const FinalizeStep1Screen(),
    ),
  );
}

// ============================================================================
// 6) Screen
// ============================================================================
class FinalizeStep1Screen extends ConsumerWidget {
  const FinalizeStep1Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st   = ref.watch(recordControllerProvider);
    final ctrl = ref.read(recordControllerProvider.notifier);

    final DateTime endedAt   = DateTime.now();
    final DateTime startedAt = st.startedAtUtc ?? endedAt.subtract(st.elapsed);
    final canNext = st.selectedMoods.isNotEmpty;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '기록하기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.textMain),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: C.textMain),
          onPressed: () async {
            final quit = await _showQuitConfirmDialog(context);
            if (quit == true) {
              final ok = await ctrl.quit(context: context);
              if (ok && context.mounted) context.go('/home');
            }
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, kBodyTopPadding, 24, 20 + 56 + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ───────────────────────────────────────────────────────────
            Row(
              children: const [
                _HeaderBoldCheck(),
                SizedBox(width: kHeaderGap),
                Text(
                  '오늘 공부',
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: C.textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Padding(
              padding: EdgeInsets.only(left: kHeaderIconSize + kHeaderGap),
              child: Text(
                '다음 정보가 맞나요?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.textSub),
              ),
            ),

            const SizedBox(height: kTitleToCardGap),

            // ── 요약 카드 ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: C.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SummaryRowPlain(label: '날짜',        valueKey: _SummaryValueKey.date),
                  SizedBox(height: 8),
                  _SummaryRowPlain(label: '순 공부 시간', valueKey: _SummaryValueKey.netStudy),
                  SizedBox(height: 8),
                  _SummaryRowPlain(label: '총 시간',      valueKey: _SummaryValueKey.total),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── 오늘 목표 ─────────────────────────────────────────────────────
            const Text(
              '오늘 목표',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.textMain),
            ),
            const SizedBox(height: 12),
            ...st.goals.asMap().entries.map((e) {
              final i = e.key;
              final g = e.value;
              final bool disabled = g.text.trim().isEmpty;

              return GoalPillRow(
                text: g.text,
                done: g.done,
                disabled: disabled,
                onToggle: (v) => ctrl.toggleGoal(i, v, context: context),
              );
            }),

            const SizedBox(height: 40),

            // ── 공간 무드 ─────────────────────────────────────────────────────
            const Text(
              '공간 무드',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.textMain),
            ),
            const SizedBox(height: 14),
            MoodChipsFixedGrid(
              selected: st.selectedMoods,
              onTap: (m) => ctrl.toggleMood(m),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canNext
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => const FinalizeStep2Screen(),
                        ),
                      );
                    }
                  : null,
              style: ButtonStyle(
                elevation: const MaterialStatePropertyAll(0),
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.disabled)) {
                    return C.primarySoft.withOpacity(0.35);
                  }
                  return C.primaryDeep;
                }),
                shape: MaterialStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
              child: const Text(
                '다음',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 7) Dialogs
// ============================================================================
Future<bool?> _showQuitConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => const _QuitDialog(),
  );
}

class _QuitDialog extends StatelessWidget {
  const _QuitDialog();

  static const Color _cardBg     = Color(0xFFF6F1FA); // 연보라 카드
  static const Color _titleColor = C.textMain;
  static const Color _subColor   = C.textSub;
  static const Color _yesBg      = Color(0xFFA7B3F1); // 네(저장)
  static const Color _noBg       = Color(0xFFB5B9C3); // 아니요(나감)

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _cardBg,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '지금 나가면\n기록이 저장되지 않아요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: _titleColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '기록을 저장하시겠어요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: _subColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(
                  child: _DialogBigButton(
                    bg: _yesBg,
                    top: '네',
                    bottom: '기록을 저장할게요',
                    isQuit: false,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _DialogBigButton(
                    bg: _noBg,
                    top: '아니요',
                    bottom: '나갈게요',
                    isQuit: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogBigButton extends StatelessWidget {
  final Color bg;
  final String top, bottom;
  final bool isQuit; // true면 나가기(pop(true)), false면 저장(pop(false))

  const _DialogBigButton({
    required this.bg,
    required this.top,
    required this.bottom,
    required this.isQuit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58, // 여유로 오버플로우 방지
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        onPressed: () => Navigator.of(context).pop(isQuit),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              top,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.0,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              bottom,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.0,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 8) Header Check & Summary Row
// ============================================================================
class _HeaderBoldCheck extends StatelessWidget {
  const _HeaderBoldCheck();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kHeaderIconSize,
      height: kHeaderIconSize,
      child: CustomPaint(
        painter: _BoldCheckPainter(
          color: C.textMain,
          stroke: kHeaderIconStroke,
        ),
      ),
    );
  }
}

class _BoldCheckPainter extends CustomPainter {
  final Color color;
  final double stroke;
  _BoldCheckPainter({required this.color, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.56)
      ..lineTo(size.width * 0.42, size.height * 0.82)
      ..lineTo(size.width * 0.88, size.height * 0.18);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BoldCheckPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.stroke != stroke;
}

// --- 요약행 ---
enum _SummaryValueKey { date, netStudy, total }

class _SummaryRowPlain extends ConsumerWidget {
  final String label;
  final _SummaryValueKey valueKey;

  const _SummaryRowPlain({required this.label, required this.valueKey});

  String _valueForKey(WidgetRef ref) {
    final st = ref.watch(recordControllerProvider);
    final DateTime endedAt   = DateTime.now();
    final DateTime startedAt = st.startedAtUtc ?? endedAt.subtract(st.elapsed);

    switch (valueKey) {
      case _SummaryValueKey.date:
        return ymd(startedAt);
      case _SummaryValueKey.netStudy:
        return fmtDur(st.elapsed);
      case _SummaryValueKey.total:
        return fmtDur(endedAt.difference(startedAt));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = _valueForKey(ref);
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: C.textMain,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.1,
              color: C.textMain,
            ),
          ),
        ),
      ],
    );
  }
}

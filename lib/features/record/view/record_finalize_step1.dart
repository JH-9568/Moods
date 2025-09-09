// lib/features/record/view/record_finalize_step1.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // ✅ 홈으로 이동하려고 추가

import 'package:moods/features/record/controller/record_controller.dart';
import 'package:moods/features/record/widget/widget.dart';
import 'record_finalize_step2.dart'; // Step2로 이동

/// ===============================
///  풀스크린 네비게이션 시작점
/// ===============================
Future<void> showRecordFinalizeFlow(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const FinalizeStep1Screen(),
    ),
  );
}

/// ===== Color & Style Tokens =====
class C {
  static const bg           = Color(0xFFF3F5FF);
  static const headerBg     = Color(0xFFA7B3F1);
  static const surface      = Colors.white;
  static const chipStroke   = Color(0xFFE5E7F4);
  static const primarySoft  = Color(0xFFA7B3F1);
  static const primaryDeep  = Color(0xFFA7B3F1);
  static const textMain     = Color(0xFF111318);
  static const textSub      = Color(0xFF8C90A4);
  static const textWeak     = Color(0xFFB7BED6);
  static const disabledFill = Color(0xFFF0F2F8);
  static const disabledTxt  = Color(0xFFB9C0D6);
}

class S {
  static const r8  = Radius.circular(8);
  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);
}

/// 라벨/태그 상수
const MOOD_TAGS = <String>[
  '트렌디한','감성적인','개방적인','자연친화적인','컨셉있는','활기찬','아늑한','조용한',
];

/// helpers
String ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String two(int v) => v.toString().padLeft(2, '0');
String fmtDur(Duration d) =>
    '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';

/// ===============================
/// Step 1 — 요약/목표/공간무드
/// ===============================
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
              if (ok && context.mounted) {
                // ✅ 홈으로 이동 (앱의 홈 경로가 /home 이므로)
                context.go('/home');
              }
            }
          },
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20 + 56 + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                _HeaderCheckDot(),
                SizedBox(width: 8),
                Text(
                  '오늘 공부',
                  style: TextStyle(
                    fontSize: 26, height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: C.textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '다음 정보가 맞나요?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.textSub),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: C.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  _SummaryRowPlain(label: '날짜', value: ymd(startedAt)),
                  const SizedBox(height: 8),
                  _SummaryRowPlain(label: '순 공부 시간', value: fmtDur(st.elapsed)),
                  const SizedBox(height: 8),
                  _SummaryRowPlain(label: '총 시간', value: fmtDur(endedAt.difference(startedAt))),
                ],
              ),
            ),

            const SizedBox(height: 40),

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

/// ===============================
/// 내부 컴포넌트
/// ===============================

/// X를 눌렀을 때 표시되는 확인 다이얼로그
/// true  → “아니요, 나갈래요” (quit)
/// false → “네, 계속 저장할래요” (그대로 머무름)
Future<bool?> _showQuitConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        title: const Text(
          '지금 나가면\n기록이 저장되지 않아요',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.textMain),
        ),
        content: const Text(
          '이어서 기록을 저장하시겠어요?',
          style: TextStyle(fontSize: 14, color: C.textSub),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: C.primaryDeep,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('네\n기록을 저장할래요', textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: const BorderSide(color: C.disabledTxt),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: C.textMain,
                backgroundColor: C.disabledFill,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('아니요\n나갈래요', textAlign: TextAlign.center),
            ),
          ),
        ],
      );
    },
  );
}

class _HeaderCheckDot extends StatelessWidget {
  const _HeaderCheckDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: const Icon(Icons.check, size: 16, color: C.primaryDeep),
    );
  }
}

class _SummaryRowPlain extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRowPlain({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: C.textMain),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w400, color: C.textMain),
          ),
        ),
      ],
    );
  }
}

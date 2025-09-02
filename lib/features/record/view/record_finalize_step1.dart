// lib/features/record/view/record_finalize_step1.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/features/record/controller/record_controller.dart';
import 'package:moods/features/record/view/record_card_preview.dart';
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
/// (언더스코프 제거 → 다른 파일에서도 import해서 사용 가능)
class C {
  static const bg           = Color(0xFFF3F5FF);
  static const sheetTop     = Colors.white;
  static const cardFill     = Color(0xFFE9ECFF);
  static const inputFill    = Colors.white;
  static const chipStroke   = Color(0xFFE8EBF8);
  static const purple       = Color(0xFF6B6BE5);
  static const purpleSoft   = Color(0xFFA7B3F1);
  static const textMain     = Color(0xFF1B1C20);
  static const textSub      = Color(0xFF9094A9);
  static const textWeak     = Color(0xFFB7BED6);
  static const disabledFill = Color(0xFFF0F2F8);
  static const disabledTxt  = Color(0xFFB9C0D6);
  static const ghost        = Color(0xFFEDEFFF);
}

class S {
  static const h48 = 48.0;
  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);
  static const r20 = Radius.circular(20);
}

/// 라벨/태그 상수
const MOOD_TAGS = <String>[
  '트렌디한','감성적인','개방적인','자연친화적인','컨셉있는','활기찬','아늑한','조용한',
];
const EMOTION_TAGS = <String>[
  '기쁨','보통','슬픔','화남','아픔','멘붕','졸림','피곤','지루함','애매모호',
];
const PLACE_FEATURES = <String>[
  '콘센트 많음','와이파이 퀄리티 좋음','소음 높음','소음 낮음','자리 많음',
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
        backgroundColor: C.sheetTop,
        elevation: 0,
        centerTitle: true,
        title: const Text('기록하기',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            // 오늘 공부 카드
            Container(
              decoration: BoxDecoration(
                color: C.cardFill,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.check_circle, size: 20, color: C.purple),
                    SizedBox(width: 8),
                    Text('오늘 공부',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('다음 정보가 맞나요?',
                      style: TextStyle(fontSize: 12, color: C.textSub)),
                  const SizedBox(height: 12),
                  SummaryRow(label: '날짜', value: ymd(startedAt)),
                  SummaryRow(label: '순 공부 시간', value: fmtDur(st.elapsed)),
                  SummaryRow(
                    label: '총 시간',
                    value: fmtDur(endedAt.difference(startedAt)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 오늘 목표
            const Text('오늘 목표',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            ...st.goals.asMap().entries.map((e) {
              final i = e.key;
              final g = e.value;
              final bool disabled = g.text.trim().isEmpty;

              return GoalPillRow(
                text: g.text.isEmpty ? '목표' : g.text,
                done: g.done,
                disabled: disabled,
                onToggle: (v) => ctrl.toggleGoal(i, v, context: context),
              );
            }),

            const SizedBox(height: 20),

            // 공간 무드
            const Text('공간 무드',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: MOOD_TAGS.map((m) {
                final on = st.selectedMoods.contains(m);
                return FilterChip(
                  label: Text(
                    m,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : C.textMain,
                    ),
                  ),
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: StadiumBorder(
                    side: BorderSide(color: on ? C.purpleSoft : C.chipStroke),
                  ),
                  backgroundColor: Colors.white,
                  selectedColor: C.purpleSoft,
                  showCheckmark: false,
                  selected: on,
                  onSelected: (_) => ctrl.toggleMood(m),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // 다음 버튼
            SizedBox(
              height: S.h48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canNext ? C.purple : C.purple.withOpacity(.35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                child: const Text(
                  '다음',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== 공용 위젯들 (Step2에서도 import해서 사용) =====

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const SummaryRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: C.textSub, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Container(
              height: 36,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: C.inputFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, color: C.textMain, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class GoalPillRow extends StatelessWidget {
  final String text;
  final bool done;
  final bool disabled;
  final Future<void> Function(bool) onToggle;

  const GoalPillRow({
    super.key,
    required this.text,
    required this.done,
    required this.disabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final Color pillBg = disabled ? C.disabledFill : (done ? C.purpleSoft : Colors.white);
    final Color txt    = disabled ? C.disabledTxt  : (done ? Colors.white : C.textMain);
    final Color boxBg  = disabled ? C.disabledFill : (done ? C.purple : const Color(0xFFE8ECF6));
    final Color iconCol= disabled ? C.textSub      : (done ? Colors.white : C.textWeak);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          InkWell(
            onTap: disabled ? null : () => onToggle(!done),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: boxBg, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Icon(disabled ? Icons.close_rounded : Icons.check_rounded,
                  size: 18, color: iconCol),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: disabled ? null : () => onToggle(!done),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  text,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: txt),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 공통 라벨
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));
  }
}

/// 공통 인풋
class InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const InputBox.text({super.key, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: C.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.chipStroke),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: InputBorder.none, isCollapsed: true,
          hintStyle: TextStyle(color: C.textSub),
        ).copyWith(hintText: hint),
      ),
    );
  }
}

/// 감정 아래 배치되는 고스트 이미지 피커(시안 위치)
class GhostImagePicker extends StatelessWidget {
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;

  const GhostImagePicker({super.key, this.onCameraTap, this.onGalleryTap});

  @override
  Widget build(BuildContext context) {
    const Color purple = Color(0xFF6C63FF);
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: C.ghost,
            border: Border.all(color: C.chipStroke),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '공간을 함께 저장해보세요',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconButtonGhost(icon: Icons.photo_camera_outlined, color: purple, onTap: onCameraTap),
                  const SizedBox(width: 20),
                  _IconButtonGhost(icon: Icons.photo_library_outlined, color: purple, onTap: onGalleryTap),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButtonGhost extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _IconButtonGhost({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 28, color: color),
      ),
    );
  }
}

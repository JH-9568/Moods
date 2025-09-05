import 'package:flutter/material.dart';

/// 디자인 토큰(컴포넌트 내부 전용)
class _RB {
  static const primarySoft  = Color(0xFFA7B3F1);
  static const surface      = Colors.white;
  static const textMain     = Color(0xFF111318);
  static const textWeak     = Color(0xFFB7BED6);
  static const textSub      = Color(0xFF8C90A4);
  static const disabledFill = Color(0xFFF0F2F8);
  static const disabledTxt  = Color(0xFFB9C0D6);
}

/// ---------------
/// 목표 한 줄 (Step1과 동일 스타일)
/// ---------------
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
    final Color pillBg = disabled ? _RB.disabledFill : (done ? _RB.primarySoft : _RB.surface);
    final Color txt    = disabled ? _RB.disabledTxt  : (done ? Colors.white : _RB.textMain);
    final Color dotBg  = disabled ? _RB.disabledFill : (done ? _RB.primarySoft : const Color(0xFFE8ECF6));
    final Color iconCol= disabled ? _RB.textSub      : (done ? Colors.white : _RB.textWeak);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          InkWell(
            onTap: disabled ? null : () => onToggle(!done),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: dotBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(
                disabled ? Icons.close_rounded : Icons.check_rounded,
                size: 18,
                color: iconCol,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: disabled ? null : () => onToggle(!done),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Text(
                  text.isEmpty ? '목표' : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

/// ---------------
/// 공간 무드 칩 (테두리 없음, 높이 34, 내용폭)
/// ---------------
class _MoodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MoodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? _RB.primarySoft : Colors.white;
    final Color fg = selected ? Colors.white : _RB.textMain;

    return Material(
      color: bg,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
        ),
      ),
    );
  }
}

/// ---------------
/// 공간 무드 고정 레이아웃(3 / 3 / 2) – Step1과 동일 배치
/// ---------------
class MoodChipsFixedGrid extends StatelessWidget {
  /// 각 행에 들어갈 라벨들. 기본값은 3/3/2 배치.
  final List<List<String>> rows;

  /// 현재 선택된 라벨 리스트(다중 선택 허용)
  final List<String> selected;

  /// 칩 탭 시 호출
  final void Function(String) onTap;

  const MoodChipsFixedGrid({
    super.key,
    this.rows = const [
      ['트렌디한','감성적인','개방적인'],
      ['자연친화적인','컨셉있는','활기찬'],
      ['아늑한','조용한'],
    ],
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          Row(
            children: [
              for (int i = 0; i < rows[r].length; i++) ...[
                _MoodChip(
                  label: rows[r][i],
                  selected: selected.contains(rows[r][i]),
                  onTap: () => onTap(rows[r][i]),
                ),
                if (i != rows[r].length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
          if (r != rows.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

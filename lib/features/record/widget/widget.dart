import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moods/common/constants/colors_j.dart';
import 'package:moods/common/constants/text_styles.dart';

class ToggleSvg extends StatelessWidget {
  final bool active;         // true=toggle_active, false=toggle_inactive
  final bool disabled;       // 탭 막기 + opacity 낮춤
  final VoidCallback? onTap;
  final double size;
  final Color? ringColor;    // 비활성 링 색상 오버라이드
  final Color? plateColor;   // 체크 아이콘 배경색 오버라이드

  const ToggleSvg({
    super.key,
    required this.active,
    required this.disabled,
    this.onTap,
    this.size = 28,
    this.ringColor,
    this.plateColor,
  });

  @override
  Widget build(BuildContext context) {
    // active일 땐 항상 active.svg
    // inactive일 땐 ringColor가 있으면 inactive.svg에 색상 오버라이드
    final String asset;
    final ColorFilter? colorFilter;

    if (active) {
      asset = 'assets/fonts/icons/toggle_active.svg';
      colorFilter = null;
    } else {
      asset = 'assets/fonts/icons/toggle_inactive.svg';
      colorFilter = ringColor != null
          ? ColorFilter.mode(ringColor!, BlendMode.srcIn)
          : null;
    }

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: SvgPicture.asset(
              asset,
              width: size - 4,
              height: size - 4,
              colorFilter: colorFilter,
            ),
          ),
        ),
      ),
    );
  }
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
    final bool isPlaceholder = text.trim().isEmpty;

    // ✅ 스타일 잠금은 "진짜 disabled"일 때만. placeholder는 기본 스타일 유지
    final bool lockStyle = disabled && !isPlaceholder;

    // ✅ 배경 통일: 완료만 채움, 나머진 흰색
    final Color pillBg = done ? AppColorsJ.main3 : Colors.white;

    // ✅ 테두리 통일: 완료=없음 / 진짜 disabled=Main2 굵게 / 그 외(placeholder 포함)=연회색
    final BorderSide side = done
        ? const BorderSide(color: Colors.transparent, width: 0)
        : (lockStyle
            ? const BorderSide(color: AppColorsJ.main2, width: 2)
            : const BorderSide(color: AppColorsJ.gray3Normal, width: 1));

    // ✅ 텍스트 크기/두께 통일 + placeholder는 연회색
    final Color txtColor =
        done ? Colors.white : (isPlaceholder ? AppColorsJ.gray5 : AppColorsJ.black);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // 토글은 placeholder도 비활성, 대신 링은 중립색으로
          ToggleSvg(
            active: done,
            disabled: disabled || isPlaceholder,
            onTap: () => onToggle(!done),
            ringColor: isPlaceholder ? AppColorsJ.gray3Normal : null,
            plateColor: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: (disabled || isPlaceholder) ? null : () => onToggle(!done),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: ShapeDecoration(
                  color: pillBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    side: side,
                  ),
                ),
                child: Text(
                  isPlaceholder ? '목표 입력' : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: txtColor),
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
/// 공간 무드 칩 (연한 회색 테두리 + 선택 시 보라 채움)
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
    final Color fill = selected ? AppColorsJ.main3 : Colors.white;
    final Color fg   = selected ? Colors.white : AppColorsJ.black;

    // Ink + ShapeDecoration을 써야 테두리(stroke)와 잉크 리플이 동시에 깔끔하게 나옴
    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(),
      child: Ink(
        decoration: ShapeDecoration(
          color: fill,
          shape: const StadiumBorder(
            side: BorderSide(color: AppColorsJ.main2, width: 1),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(label,
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500, color: fg)),
          ),
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

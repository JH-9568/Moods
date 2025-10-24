// lib/features/home/widget/prefer_keyword/prefer_keyword_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/prefer_keyword/prefer_keyword_service.dart';
import 'package:moods/features/home/widget/prefer_keyword/prefer_keyword_controller.dart';
import 'package:moods/providers.dart';

/// 선호공간 키워드 섹션 (제목 + 타입/무드/특징 3줄)
class PreferKeywordSection extends ConsumerWidget {
  const PreferKeywordSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(preferKeywordControllerProvider);
    final notifier = ref.read(preferKeywordControllerProvider.notifier);

    // 최초 1회 자동 로딩
    if (!state.loading && !state.loadedOnce && state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.loadIfNeeded();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 타이틀
        Text('선호공간 키워드', style: AppTextStyles.bodyBold),
        const SizedBox(height: 12),

        if (state.loading && !state.loadedOnce)
          const _LoadingSkeleton()
        else ...[
          // 타입
          _KeywordRow(
            label: '타입',
            labelStyle: AppTextStyles.small.copyWith(
              color: AppColors.text_color2,
            ),
            items: state.types,
            chipKind: _ChipKind.light, // 흰 배경, 검정 텍스트
          ),
          const SizedBox(height: 10),

          // 무드
          _KeywordRow(
            label: '무드',
            labelStyle: AppTextStyles.small.copyWith(
              color: AppColors.text_color2,
            ),
            items: state.moods,
            chipKind: _ChipKind.filled, // AppColors.sub 배경, 흰 텍스트
          ),
          const SizedBox(height: 10),

          // 특징
          _KeywordRow(
            label: '특징',
            labelStyle: AppTextStyles.small.copyWith(
              color: AppColors.text_color2,
            ),
            items: state.features,
            chipKind: _ChipKind.light, // 흰 배경, 검정 텍스트
          ),
        ],

        if (state.error != null && state.error!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            state.error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

/// 단일 라인: 왼쪽 라벨 + 오른쪽 칩 리스트
class _KeywordRow extends StatelessWidget {
  final String label;
  final TextStyle labelStyle;
  final List<PreferKeyword> items;
  final _ChipKind chipKind;

  const _KeywordRow({
    required this.label,
    required this.labelStyle,
    required this.items,
    required this.chipKind,
  });

  @override
  Widget build(BuildContext context) {
    // 최대 2개까지만 표시
    final displayItems = items.take(2).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 왼쪽 라벨
        Text(label, style: labelStyle),
        const SizedBox(width: 12),
        // 오른쪽 칩들 (자동 줄바꿈)
        Flexible(
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            children: displayItems.isEmpty
                ? [const _EmptyHint()]
                : displayItems
                      .map((e) => _KeywordChip(text: e.label, kind: chipKind))
                      .toList(),
          ),
        ),
      ],
    );
  }
}

enum _ChipKind { light, filled }

/// 키워드 칩: 라운드 12, 내부 패딩으로 길이 자동 확장
class _KeywordChip extends StatelessWidget {
  final String text;
  final _ChipKind kind;

  const _KeywordChip({required this.text, required this.kind});

  @override
  Widget build(BuildContext context) {
    final bool filled = kind == _ChipKind.filled;

    final bg = filled ? AppColors.sub : Colors.white;
    final fg = filled ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        // 공통: AppTextStyles.small 사용
        style: AppTextStyles.small.copyWith(color: fg),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

/// 로딩 스켈레톤 (간단한 자리표시자)
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar({double w = 60}) => Container(
      width: w,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.unchecked,
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: 48, child: bar(w: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [bar(w: 68), bar(w: 96), bar(w: 72)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(width: 48, child: bar(w: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [bar(w: 74), bar(w: 88)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            SizedBox(width: 48, child: bar(w: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [bar(w: 96), bar(w: 82), bar(w: 84)],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Text(
      '아직 선호 공간이 없어요!',
      style: AppTextStyles.small.copyWith(color: AppColors.text_color2),
    );
  }
}

// lib/features/home/widget/my_ranking/my_ranking_empty.dart
import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';

class RankingEmptyCard extends StatelessWidget {
  const RankingEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 361,
      height: 143,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '나의 공간 랭킹',
              style: AppTextStyles.title.copyWith(color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '현재 기록이 없어요',
              style: AppTextStyles.small.copyWith(color: AppColors.text_color2),
              textAlign: TextAlign.center,
            ),

            Text(
              '공부 기록을 쌓아보세요!',
              style: AppTextStyles.small.copyWith(color: AppColors.text_color2),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

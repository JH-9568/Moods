import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';

/// 홈 화면의 "나의 공간 랭킹" 빈 상태 섹션을 단독 위젯으로 분리.
/// HomeScreen의 _buildCard 스타일을 그대로 복제해서 동일한 UI를 유지한다.
class RankingEmptyCard extends StatelessWidget {
  const RankingEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 4),
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
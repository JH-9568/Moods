import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 홈 화면의 "공부 기록" 빈 상태 섹션
class StudyRecordEmptyCard extends StatelessWidget {
  const StudyRecordEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.border, // 연한 파랑 배경
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 3,
            top: 0,
            child: SvgPicture.asset(
              'assets/fonts/icons/calender.svg',
            ),
          ),
          // 중앙 텍스트
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '공부 기록',
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
        ],
      ),
    );
  }
}
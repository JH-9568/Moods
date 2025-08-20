

import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/my_moods/study_count_widget.dart';

/// 홈 화면의 "나만의 Moods" 카드 섹션
/// 기존 _buildCard 블록을 분리한 재사용 위젯.
/// - [studyCount]: 현재 공부 횟수
/// - [onStartPressed]: "공부 시작하기" 버튼을 눌렀을 때 실행할 콜백

class MyMoodsSection extends StatelessWidget {
  final int studyCount;
  final VoidCallback onStartPressed;

  const MyMoodsSection({
    super.key,
    required this.studyCount,
    required this.onStartPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 공부 횟수 게이지
          StudyCountWidget(studyCount: studyCount),
          const SizedBox(height: 12),
          // 제목 (원래 _buildCard의 title 파라미터에 있던 값)
          Text(
            '나만의 Moods',
            style: AppTextStyles.title.copyWith(color: Colors.black),
          ),
          const SizedBox(height: 3),
          // 본문 설명
          Text(
            '공간 기록과 함께 공부를 시작해보세요',
            style: AppTextStyles.bodyBold.copyWith(color: Colors.black),
          ),
          const SizedBox(height: 30),
          
          // 공부 시작하기 버튼
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onStartPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.main,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '공부 시작하기',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
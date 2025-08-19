import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';

/// 홈 - "공부 기록" 섹션 컨테이너 (카드 제외 + 가로 슬라이더 더미 카드)
class StudyRecordSection extends StatelessWidget {
  const StudyRecordSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.border,                 // 요청한 배경색
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (제목 + 우상단 아이콘)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '공부 기록',
                  style: AppTextStyles.title.copyWith(color: Colors.black),
                ),
              ),
              SvgPicture.asset(
                'assets/fonts/icons/calender.svg',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 가로 슬라이드 더미 카드 5개
          const _DummyRecordCarousel(),
        ],
      ),
    );
  }
}

/// 내부 전용: 검정색 더미 카드 5개를 가로 스크롤로 보여주는 위젯
class _DummyRecordCarousel extends StatelessWidget {
  const _DummyRecordCarousel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 123.44, // 카드 높이 + 그림자 여유
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          return Container(
            width: 79,
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 1,
                  offset: const Offset(0, 0.1),
                ),
              ],
            ),
            child: const Center(
              child: Text('Card', style: TextStyle(color: Colors.white)),
            ),
          );
        },
      ),
    );
  }
}
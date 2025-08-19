import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_widget.dart';

/// 홈 - "나의 공간 랭킹" 섹션 컨테이너
/// 카드(랭킹 아이템)들은 별도 위젯에서 그리도록 분리.
class MyRankingSection extends StatelessWidget {
  const MyRankingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.border, // 연한 파랑 배경
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            '나의 공간 랭킹',
            style: AppTextStyles.title.copyWith(color: Colors.black),
          ),
          const SizedBox(height: 6),
          // 서브 타이틀
          Text(
            '내가 가장 많이 공부한 공간은?',
            style: AppTextStyles.small.copyWith(color: AppColors.text_color2),
          ),
          const SizedBox(height: 1),
          ArcRankingCarousel(
            items: const [
              RankingItem('스타벅스 A점', Duration(hours: 32, minutes: 30)),
              RankingItem('독서실 B', Duration(hours: 24)),
              RankingItem('카페 C', Duration(hours: 18)),
              RankingItem('도서관 D', Duration(hours: 12)),
              RankingItem('집 E', Duration(hours: 8)),
            ],
            itemSize: Size(94.06, 146.97),
            radius: 110,
          ),
        ],
      ),
    );
  }
}

class _DummyRecordCarousel extends StatelessWidget {
  const _DummyRecordCarousel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('Record 1')),
          ),
          Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.blue[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('Record 2')),
          ),
          Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.blue[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('Record 3')),
          ),
        ],
      ),
    );
  }
}

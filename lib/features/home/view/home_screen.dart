import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/home/widget/study_record/providers/study_record_providers.dart';
import 'package:flutter/material.dart';
import 'package:moods/common/widgets/custom_app_bar.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/features/home/widget/my_moods/my_moods_section.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_section.dart';
import 'package:moods/features/home/widget/study_count/study_count_widget.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/study_record/study_record_empty.dart';
import 'package:moods/features/home/widget/my_ranking/my_ranking_empty.dart';
import 'package:moods/features/home/widget/study_record/ui/study_record_section.dart';
import 'package:moods/features/home/widget/study_time/study_time_widget.dart';
import 'package:moods/common/constants/api_constants.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int studyCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(studyRecordProvider.notifier).loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 예시: home_page.dart 일부
              const TotalStudyTimeWidget(
                showSegment: true, // 세그먼트(이번 달/이번 주) 표시
              ),
              StudyCountWidget(studyCount: studyCount),
              const SizedBox(height: 16),
              // 1. 나만의 Moods
              MyMoodsSection(
                studyCount: studyCount,
                onStartPressed: () {
                  setState(() {
                    studyCount++;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 2. 나의 공간 랭킹 (빈 상태)
              const RankingEmptyCard(),
              const SizedBox(height: 16),

              // 3. 공부 기록 (빈 상태)
              const StudyRecordEmptyCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// 공통 카드 빌더
  Widget _buildCard({
    required String title,
    required Widget child,
    double? height,
    Color backgroundColor = AppColors.border,
  }) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: 1.5),
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:moods/common/widgets/custom_app_bar.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/features/home/widget/study_count_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int studyCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
            // 1. 나만의 Moods
            _buildCard(
              title: '나만의 Moods',
              backgroundColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '공간 기록과 함께 공부를 시작해보세요',
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  const SizedBox(height: 12),

                  // 학습 횟수 라벨 및 슬라이더 (레이블드 틱 레일)
                  const SizedBox(height: 20),
                  StudyCountWidget(studyCount: studyCount),

                  const SizedBox(height: 20,),

                  // 공부 시작하기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => studyCount++);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.main,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '공부 시작하기',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. 나의 공간 랭킹 (빈 상태)
            _buildCard(
              title: '나의 공간 랭킹',
              backgroundColor: AppColors.border,
              child: SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    '아직 랭킹이 없습니다',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. 공부 기록 (빈 상태)
            _buildCard(
              title: '공부 기록',
              child: SizedBox(
                height: 250,
                child: Center(
                  child: Text(
                    '아직 기록이 없습니다',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
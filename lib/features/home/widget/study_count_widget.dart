import 'package:flutter/material.dart';
import 'package:step_progress/step_progress.dart';
import 'package:moods/common/constants/colors.dart';

class StudyCountWidget extends StatelessWidget {
  final int studyCount;

  const StudyCountWidget({super.key, required this.studyCount});

  @override
  Widget build(BuildContext context) {
    final int currentStep = (studyCount / 5).clamp(0, 5).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '나의 공부 횟수',
          style: TextStyle(
            color: AppColors.text_color1,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        StepProgress(
          totalSteps: 6,
          currentStep: currentStep,
          padding: EdgeInsets.all(1),
          stepSize: 16,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('0회', style: TextStyle(fontSize: 12, color: Color(0xFFB0B9C7))),
            Text('5회', style: TextStyle(fontSize: 12, color: Color(0xFFB0B9C7))),
            Text('10회', style: TextStyle(fontSize: 12, color: Color(0xFFB0B9C7))),
            Text('15회', style: TextStyle(fontSize: 12, color: Color(0xFFB0B9C7))),
            Text('20회', style: TextStyle(fontSize: 12, color: Color(0xFFB0B9C7))),
            Text('25회', style: TextStyle(fontSize: 12, color: Color(0xFFB0B9C7))),
          ],
        )
      ],
    );
  }
}
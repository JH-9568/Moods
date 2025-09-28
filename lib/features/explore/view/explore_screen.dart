import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/features/calendar/dropdown/calendar_header.dart';
import 'package:moods/features/calendar/widget/calendar_widget.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  YearMonth _ym = YearMonth.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더: "2025년 7월 ▼" (탭하면 커스텀 date picker)
            const SizedBox(height: 8),

            // 캘린더 본문
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                // ⬇️ 네가 만든 CalendarWidget이 파라미터를 안 받는다면 이대로 사용
                child: const CalendarWidget(),

                // 만약 CalendarWidget이 연/월을 받도록 만들었다면 이렇게 바꿔 사용해:
                // child: CalendarWidget(year: _ym.year, month: _ym.month),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

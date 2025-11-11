// lib/features/explore/view/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/features/calendar/widget/calendar_widget.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          // CalendarWidget에는 헤더와 본문이 모두 포함되어 있다
          child: CalendarWidget(),
        ),
      ),
    );
  }
}

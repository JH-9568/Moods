// lib/features/my_page/my_page_study_record_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';

// API/모델/컨트롤러 재사용 (최근 방문 공간)
import 'package:moods/features/home/widget/study_record/home_record_controller.dart';
import 'package:moods/features/home/widget/study_record/home_record_service.dart';
import 'package:moods/features/home/widget/study_record/home_record_empty.dart';

/// 마이페이지용 "공부 기록" 카드 위젯 (하얀 카드 + 제목/설명 + 캘린더 아이콘 + 가로 스크롤 카드)
class MyPageStudyRecordWidget extends ConsumerWidget {
  const MyPageStudyRecordWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeRecordControllerProvider);
    final notifier = ref.read(homeRecordControllerProvider.notifier);

    // 첫 진입 시 자동 로드 (중복 호출 방지)
    if (!state.loading && !state.loadedOnce && state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.loadIfNeeded();
      });
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.border, // 마이페이지용 하얀 카드
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 : 제목 + 캘린더 아이콘
          Row(
            children: [
              Expanded(child: Text('공부 기록', style: AppTextStyles.bodyBold)),
              // 캘린더 아이콘
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          // 서브 텍스트
          Text(
            '나의 공부 기록을 최신순으로 확인해보세요',
            style: AppTextStyles.small.copyWith(color: AppColors.text_color2),
          ),
          const SizedBox(height: 12),

          // 본문
          if (state.loading && !state.loadedOnce)
            const _RecordSkeleton()
          else if (state.error != null || state.items.isEmpty)
            const StudyRecordEmptyCard()
          else
            _RecordList(items: state.items.take(20).toList()),
        ],
      ),
    );
  }
}

/// 가로 스크롤 카드 리스트 (마이페이지용)
class _RecordList extends StatelessWidget {
  final List<RecentSpace> items;
  const _RecordList({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 123.44, // 카드 높이에 맞춤
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (ctx, i) => _RecordCard(item: items[i]),
      ),
    );
  }
}

/// 단일 카드 (마이페이지용)
class _RecordCard extends StatelessWidget {
  final RecentSpace item;
  const _RecordCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateText = item.lastVisitDateText ?? '';
    final hasImage =
        (item.spaceImageUrl != null && item.spaceImageUrl!.trim().isNotEmpty);

    return Container(
      width: 79,
      height: 123.44,
      decoration: BoxDecoration(
        color: Colors.white,
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(item.spaceImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 하단 정보 바
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 40,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 (yyyy-MM-dd 그대로)
                  Text(
                    dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(
                      fontSize: 7,
                      height: 1.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 지점명
                  Text(
                    item.spaceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 10,
                      height: 1.0,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 로딩 스켈레톤 (마이페이지용)
class _RecordSkeleton extends StatelessWidget {
  const _RecordSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 123.44,
      child: Row(
        children: List.generate(
          4,
          (_) => Container(
            width: 79,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.unchecked,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

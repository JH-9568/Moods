// lib/features/home/widget/home_record/home_record_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/study_record/home_record_controller.dart';
import 'package:moods/features/home/widget/study_record/home_record_empty.dart';
import 'package:moods/features/home/widget/study_record/home_record_service.dart';

/// “최근 방문 공간” 섹션 전체 위젯
class HomeRecordSection extends ConsumerWidget {
  const HomeRecordSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeRecordControllerProvider);
    final notifier = ref.read(homeRecordControllerProvider.notifier);

    // 첫 진입 시 자동 로드
    if (!state.loading && !state.loadedOnce && state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.loadIfNeeded();
      });
    }

    return Container(
      width: 361,
      height: 386,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My 공간', style: AppTextStyles.title),
          const SizedBox(height: 12),
          Text('최근 방문 공간', style: AppTextStyles.bodyBold),
          const SizedBox(height: 12),

          if (state.loading && !state.loadedOnce)
            const _RecordSkeleton()
          else if (state.error != null || state.items.isEmpty)
            const StudyRecordEmptyCard()
          else ...[
            _RecordList(items: state.items.take(20).toList()),
            const SizedBox(height: 15), // 사진 목록과 키워드 텍스트 사이 간격
            Text(
              '선호공간 키워드', // 👈 추가된 줄
              style: AppTextStyles.bodyBold,
            ),
          ],
        ],
      ),
    );
  }
}

/// 가로 스크롤 카드 리스트
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

/// 단일 카드
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
          // 하단 정보 바 (오버플로우 방지: 높이/패딩/폰트 조정)
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
                  // 날짜
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

/// 로딩 스켈레톤
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

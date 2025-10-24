// lib/features/home/widget/home_record/home_record_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/prefer_keyword/prefer_keyword_widget.dart';
import 'package:moods/features/home/widget/study_record/home_record_controller.dart';
import 'package:moods/features/home/widget/study_record/home_record_empty.dart';
import 'package:moods/features/home/widget/study_record/home_record_service.dart';

/// "최근 방문 공간" 섹션 전체 위젯
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

    // ✅ 기록이 없거나(빈 목록) 에러면: 컨테이너/헤더 없이 "빈 상태 카드"만 보여줌
    if (state.loadedOnce && (state.error != null || state.items.isEmpty)) {
      return const StudyRecordEmptyCard();
    }

    // ⏳ 초기 로딩(아직 데이터 결정 전)에는 스켈레톤만 필요하면 이렇게 바로 반환해도 됨
    if (state.loading && !state.loadedOnce) {
      return const _RecordSkeleton();
    }

    // ✅ 정상 데이터가 있을 때만 기존 섹션 컨테이너 렌더링
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

          _RecordList(items: state.items.take(20).toList()),
          const SizedBox(height: 15),
          PreferKeywordSection(),
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
      height: 123.44,
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

    final boxShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 6,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];

    return Container(
      width: 79,
      height: 123.44,
      decoration: BoxDecoration(color: Colors.white, boxShadow: boxShadow),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 배경 이미지
          if (hasImage)
            Positioned.fill(
              child: Image.network(item.spaceImageUrl!, fit: BoxFit.cover),
            ),

          // 🎨 흰색 그라데이션 오버레이 (위 0% → 아래 100%)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0), // 위는 투명
                    Colors.white.withOpacity(1.0), // 아래는 흰색 (텍스트 읽기용)
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ✅ 하단 텍스트 (흰색 배경 제거됨)
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 7,
                      height: 1.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
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
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => Container(
          width: 79,
          decoration: BoxDecoration(
            color: AppColors.unchecked,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

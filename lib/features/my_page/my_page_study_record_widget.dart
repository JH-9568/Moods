// lib/features/my_page/my_page_study_record_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
              Expanded(
                child: Text(
                  '공부 기록',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // 캘린더 아이콘
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Transform.translate(
                  // ⬅️ 위치 조정 (x, y 값은 필요에 맞게 조절하세요)
                  offset: const Offset(-5, 2),
                  child: SvgPicture.asset(
                    'assets/fonts/icons/calender.svg',
                    width: 20,
                    height: 20,
                    fit: BoxFit.none, // 아이콘이 scale되지 않고 원래 크기 유지
                  ),
                ),
              ),
            ],
          ),

          // 서브 텍스트
          // 서브 텍스트
          Transform.translate(
            offset: const Offset(0, -3), // ← 위로 3px 당김 (원하면 -2 ~ -4로 미세조정)
            child: Text(
              '나의 공부 기록을 최신순으로 확인해보세요',
              style: AppTextStyles.small.copyWith(color: AppColors.text_color2),
            ),
          ),
          const SizedBox(height: 10),

          // 본문
          if (state.loading && !state.loadedOnce)
            const _RecordSkeleton()
          else if (state.error != null || state.items.isEmpty)
            const StudyRecordEmptyCard()
          else
            _RecordList(items: state.items.take(20).toList()),
          SizedBox(height: 8),
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
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) => _RecordCard(item: items[i]),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final RecentSpace item;
  const _RecordCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateText = item.lastVisitDateText ?? '';
    final hasImage =
        (item.spaceImageUrl != null && item.spaceImageUrl!.trim().isNotEmpty);

    final durationText = item.durationKorean; // 🔹 “2시간 30분” 등

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
              height: 50, // ⬆️ 40 -> 50 (한 줄 추가되니 살짝 키움)
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 지점명
                  Text(
                    item.spaceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyBold.copyWith(
                      fontSize: 9,
                      height: 1.0,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // 🔹 공부 시간(없으면 표시 생략)
                  if (durationText.isNotEmpty) ...[
                    Text(
                      durationText, // 예: 2시간 30분
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 11, // 카드 폭(79)에 맞춰 적당히
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],

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

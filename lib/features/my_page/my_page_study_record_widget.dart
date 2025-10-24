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
import 'package:go_router/go_router.dart';
import 'package:moods/providers.dart' show calendarControllerProvider;

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
              // 캘린더 아이콘 버튼
              Semantics(
                button: true,
                label: '캘린더 열기',
                child: InkWell(
                  onTap: () {
                    // ✅ 캘린더 데이터 미리 요청
                    final ctrl = ref.read(calendarControllerProvider.notifier);
                    // (옵션) 혹시 현재 월을 확실히 강제하고 싶으면 아래 라인도 함께:
                    ctrl.changeMonth(DateTime.now());
                    ctrl.fetchMonth(); // 현재 month 기준으로 요청

                    // 그리고 캘린더 화면으로 이동
                    context.push('/profile/calendar');
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Transform.translate(
                      offset: const Offset(-5, 2),
                      child: SvgPicture.asset(
                        'assets/fonts/icons/calender.svg',
                        width: 20,
                        height: 20,
                        fit: BoxFit.none,
                      ),
                    ),
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

    final durationText = item.durationKorean; // “2시간 30분” 등

    return Container(
      width: 79,
      height: 123.44,
      decoration: const BoxDecoration(
        color: Colors.white, // 카드 바탕(이미지 없는 경우 대비)
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 배경 이미지
          if (hasImage)
            Positioned.fill(
              child: Image.network(item.spaceImageUrl!, fit: BoxFit.cover),
            ),

          // 🎨 흰색 그라데이션 오버레이 (위=투명 → 아래=흰색)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(1.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ✅ 하단 텍스트 (흰색 박스 제거: color 삭제, padding만 유지)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 지점명 (그대로)
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

                  // 공부 시간 (그대로, 없으면 표시 X)
                  if (durationText.isNotEmpty) ...[
                    Text(
                      durationText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 11,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],

                  // 날짜 (그대로)
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

/// 로딩 스켈레톤 (마이페이지용) — 가로 스크롤로 변경하여 오버플로우 방지
class _RecordSkeleton extends StatelessWidget {
  const _RecordSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 123.44,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/home/widget/study_record/model/study_session_view.dart';
import 'package:moods/features/home/widget/study_record/providers/study_record_providers.dart';

class StudyRecordSection extends ConsumerWidget {
  const StudyRecordSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studyRecordProvider);
    final controller = ref.read(studyRecordProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '공부 기록',
                  style: AppTextStyles.title.copyWith(color: Colors.black),
                ),
              ),
              GestureDetector(
                onTap: controller.refresh,
                child: SvgPicture.asset('assets/fonts/icons/calender.svg'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4가지 상태 처리
          state.list.when(
            loading: () => const _SkeletonCarousel(),
            error: (e, _) => _ErrorState(message: '불러오기 실패: $e', onRetry: controller.refresh),
            data: (items) {
              // ignore: avoid_print
              print('[UI] StudyRecordSection items = ${items.length}');
              if (items.isEmpty) {
                return _EmptyState(onCreateNew: () => controller.startOptimistic('새 공부'));
              }
              return _RecordCarousel(
                items: items,
                isLoadingMore: state.isLoadingMore,
                onLoadMore: controller.loadMore,
                onTapCard: (it) {
                  // TODO: 상세 페이지 이동 등
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ===== Dumb View 이하 =====

class _RecordCarousel extends StatefulWidget {
  final List<StudySessionView> items;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final void Function(StudySessionView) onTapCard;
  const _RecordCarousel({
    required this.items,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onTapCard,
  });

  @override
  State<_RecordCarousel> createState() => _RecordCarouselState();
}

class _RecordCarouselState extends State<_RecordCarousel> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.maxScrollExtent - _controller.position.pixels < 100) {
        widget.onLoadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return SizedBox(
      height: 170,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: items.length + (widget.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          if (index >= items.length) {
            return const SizedBox(
              width: 120,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final it = items[index];
          return _StudyCard(item: it, onTap: () => widget.onTapCard(it));
        },
      ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  final StudySessionView item;
  final VoidCallback onTap;
  const _StudyCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final running = item.endAtLocal == null;
    final durationText = item.durationMinutes != null
        ? '${item.durationMinutes}분'
        : (running ? '진행 중…' : '-');

    return PhysicalModel(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.zero,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isOptimistic)
                  const Row(
                    children: [
                      Icon(Icons.sync, size: 14, color: Colors.white70),
                      SizedBox(width: 4),
                      Text('동기화 대기', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(item.locationName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87, fontSize: 12)),
                const SizedBox(height: 4),
                Text(durationText, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCarousel extends StatelessWidget {
  const _SkeletonCarousel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) {
          return Container(
            width: 120,
            decoration: const BoxDecoration(color: Color(0xFFEDEDED)),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateNew;
  const _EmptyState({required this.onCreateNew});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const Icon(Icons.menu_book_outlined),
          const SizedBox(width: 12),
          const Expanded(child: Text('아직 공부 기록이 없어요. 첫 기록을 시작해보세요.')),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: onCreateNew, child: const Text('공부 시작')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
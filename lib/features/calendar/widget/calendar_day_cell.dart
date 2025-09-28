import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/calendar/calendar_service.dart';

/// 하루 셀: 경계선 없음, 기록이 있으면 상단에 카드(썸네일)들이 들어가고
/// 하단에 날짜 숫자가 표시되는 형태.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({super.key, required this.date, required this.items});

  final DateTime date;
  final List<CalendarVisitItem> items;

  @override
  Widget build(BuildContext context) {
    // 디자이너 시안처럼 텍스트는 아래, 위엔 썸네일들이 Wrap으로 배치
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 기록 카드(있을 때만)
        if (items.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.take(4).map((it) {
              // 아주 작은 썸네일 카드 (경계선 없이 이미지/텍스트)
              return _MiniCard(item: it);
            }).toList(),
          ),

        const Spacer(),

        // 날짜 숫자 (오른쪽 정렬 느낌 → Row 끝에)
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  '${date.day}',
                  style: AppTextStyles.small.copyWith(color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.item});
  final CalendarVisitItem item;

  @override
  Widget build(BuildContext context) {
    // 사진/이름/시간/날짜 간략 표기 (아주 작은 카드)
    return Container(
      width: 56,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          // 아주 옅은 그림자만
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        borderRadius: BorderRadius.circular(6),
        image: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            ? DecorationImage(
                image: NetworkImage(item.imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 하단 텍스트 영역(살짝 그라데이션 필요하면 추가 가능)
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 3),
              color: Colors.white.withOpacity(0.90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 지점명 (아주 작게 1줄)
                  Text(
                    item.spaceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.0,
                    ),
                  ),
                  // 시간 또는 날짜 (있으면)
                  Text(
                    item.durationDisplay ?? _yyyyMmDd(item.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.0,
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

  String _yyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

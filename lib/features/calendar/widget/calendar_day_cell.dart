import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/calendar/calendar_controller.dart';
import 'package:moods/common/constants/api_constants.dart' show baseUrl;

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.items,
    this.isPlaceholder = false,
    this.isFirstColumn = false,
    this.isFirstRow = false,
    this.onTapRecord,
    required this.formatHHMM,
  });

  final DateTime date;
  final List<CalendarRecord> items;
  final bool isPlaceholder;
  final bool isFirstColumn;
  final bool isFirstRow;
  final void Function(String recordId)? onTapRecord;
  final String Function(int seconds) formatHHMM;

  static const double _cardWidth = 48;
  static const double _cardHeight = 75;

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String? _firstImageUrl() {
    if (items.isEmpty) return null;

    String? pickFromMap(Map m) {
      // 1) 평탄화 키
      for (final k in const [
        'image_url',
        'space_image_url',
        'imageUrl',
        'thumbnail_url',
        'thumbnail',
        'cover_url',
        'photo',
      ]) {
        final v = m[k];
        if (v is String && v.trim().isNotEmpty) {
          return _normalizeUrl(v.trim());
        }
      }

      // 2) 리스트/중첩 케이스
      final images = m['images'];
      if (images is List && images.isNotEmpty) {
        final first = images.first;
        final url = (first is Map) ? first['url'] : null;
        if (url is String && url.trim().isNotEmpty) {
          return _normalizeUrl(url.trim());
        }
      }

      final media = m['media'];
      if (media is Map) {
        final thumb = media['thumbnail'] ?? media['url'];
        if (thumb is String && thumb.trim().isNotEmpty) {
          return _normalizeUrl(thumb.trim());
        }
      }

      return null;
    }

    // ✅ 하루의 모든 레코드 순회하며 첫 유효 URL 사용
    for (final rec in items) {
      final m = rec.raw;
      final url = pickFromMap(m);
      if (url != null) return url;
    }

    return null;
  }

  String _normalizeUrl(String src) {
    if (src.startsWith('http://') || src.startsWith('https://')) return src;
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final path = src.startsWith('/') ? src : '/$src';
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final hasCard = items.isNotEmpty && !isPlaceholder;
    final isToday = !isPlaceholder && _isSameDate(date, DateTime.now());
    final dailyCount = hasCard ? items.length : 0;

    const gridSide = BorderSide(
      color: Color.fromRGBO(247, 243, 240, 1),
      width: 1,
    );

    final first = hasCard ? items.first : null;
    final imageUrl = _firstImageUrl();
    final spaceName = first?.spaceName ?? '';
    final studyHHMM = first != null ? formatHHMM(first.durationSeconds) : '';

    Widget _dateBadge() {
      if (isPlaceholder) return const SizedBox.shrink();

      if (!isToday) {
        return Text(
          '${date.day}',
          style: AppTextStyles.subtitle.copyWith(
            color: hasCard
                ? AppColors.main
                : const Color.fromRGBO(239, 232, 227, 1),
            height: 1.0,
          ),
        );
      }

      return Container(
        width: 48,
        height: 23,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.sub,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${date.day}',
          style: AppTextStyles.subtitle.copyWith(
            color: Colors.white,
            height: 1.0,
          ),
        ),
      );
    }

    Widget _card() {
      if (!hasCard) return const SizedBox.shrink();

      final content = SizedBox(
        width: _cardWidth,
        height: _cardHeight,
        child: ClipRRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),

              // 카드 내부 좌상단 카운트
              if (dailyCount > 1)
                Positioned(
                  left: 3,
                  top: 4,
                  child: Container(
                    width: 13,
                    height: 13,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.sub,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '$dailyCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

              // 하단 정보 레이어(공간명/시간)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.white.withOpacity(0.9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        spaceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        studyHHMM,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
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
        ),
      );

      if (onTapRecord == null) return content;
      return InkWell(
        onTap: () => onTapRecord!(items.first.recordId),
        borderRadius: BorderRadius.circular(6),
        child: content,
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: isFirstColumn ? gridSide : BorderSide.none,
          top: isFirstRow ? gridSide : BorderSide.none,
          right: gridSide,
          bottom: gridSide,
        ),
      ),
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 25, child: Center(child: _dateBadge())),
          const Spacer(),
          _card(),
        ],
      ),
    );
  }
}

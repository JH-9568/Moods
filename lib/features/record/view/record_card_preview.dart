// lib/features/record/view/record_card_preview.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ===== 색상 토큰 (시안 기준) =====
class RC {
  static const purple = Color(0xFF6B6BE5);
  static const chip = Color(0xFFA7B3F1);
  static const chipStroke = Color(0xFFE8EBF8);
  static const textPrimary = Color(0xFF1B1C20);
  static const textSub = Color(0xFF9094A9);
}

/// ===== 데이터 모델 =====
class RecordCardData {
  final DateTime date;
  final Duration focusTime;     // 순 공부 시간
  final Duration totalTime;     // 총 시간
  final String title;           // 카드 제목(공부 제목)
  final List<String> goalsDone; // 체크된 목표 목록
  final List<String> moods;     // 이모지 포함 라벨
  final String placeName;       // 장소 이름
  final String placeType;       // 공간 타입
  final String placeMood;       // 공간 무드
  final List<String> tags;      // 태그 칩
  final ImageProvider? background; // 배경 이미지

  const RecordCardData({
    required this.date,
    required this.focusTime,
    required this.totalTime,
    required this.title,
    required this.goalsDone,
    required this.moods,
    required this.placeName,
    required this.placeType,
    required this.placeMood,
    required this.tags,
    this.background,
  });
}

/// ====== 프레젠터(오버레이) ======
/// Step2에서: await showRecordCardPreview(context, data);
Future<void> showRecordCardPreview(BuildContext context, RecordCardData data) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.35), // ← 뒤 배경 살짝 어둡게
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (ctx, a1, a2) {
      return _RecordCardOverlay(data: data);
    },
  );
}

/// ====== 기존 이름 유지용 스크린 래퍼 ======
/// 라우트에서 RecordCardPreviewScreen(data: ...)을 그대로 써도 동일하게 보임.
class RecordCardPreviewScreen extends StatelessWidget {
  final RecordCardData data;
  const RecordCardPreviewScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // showGeneralDialog가 아니어도 동일 UI가 나오도록 오버레이 뷰를 직접 렌더
    return Material(
      color: Colors.black.withOpacity(0.35), // showGeneralDialog와 동일 톤
      child: _RecordCardOverlay(data: data),
    );
  }
}

class _RecordCardOverlay extends StatelessWidget {
  final RecordCardData data;
  const _RecordCardOverlay({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // 헤더 없음
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // 카드 영역
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 329,
                  height: 622,
                  child: _RecordCard(data: data),
                ),
              ),
            ),
            // 확인 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: RC.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => context.go('/home'),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== 단일 카드 위젯 =====
class _RecordCard extends StatelessWidget {
  final RecordCardData data;
  const _RecordCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bg = data.background ??
        const AssetImage('assets/images/sample_space.jpg');

    // 포맷
    String two(int v) => v.toString().padLeft(2, '0');
    String d2(Duration d) =>
        '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
    final y = data.date.year.toString().padLeft(4, '0');
    final m = two(data.date.month);
    final d = two(data.date.day);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8), // ← r=8
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지
          DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(image: bg, fit: BoxFit.cover),
            ),
          ),
          // 살짝 어둡게 + 위/아래 그라데이션
          Container(color: Colors.black.withOpacity(0.25)),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 230,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // 내용
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 상단 바: "기록카드" + 공유/다운로드
                Row(
                  children: [
                    const Text(
                      '기록카드',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26, // ← 26
                        height: 1.30,  // ← 1.30
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _RoundIcon(onTap: () {}, icon: Icons.ios_share_rounded),
                    const SizedBox(width: 8),
                    _RoundIcon(onTap: () {}, icon: Icons.download_rounded),
                  ],
                ),

                // ***** 시간을 위로 당김: Spacer 제거하고 고정 여백만 *****
                const SizedBox(height: 18),

                // 날짜 (중앙정렬)
                Text(
                  '$y-$m-$d',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16, // ← 16
                    height: 1.40,  // ← 1.40
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // 큰 시계 (순 공부 시간) 중앙정렬
                FittedBox(
                  alignment: Alignment.center,
                  child: Text(
                    _fmtBigClock(data.focusTime),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 50,   // ← 50
                      height: 1.30,   // ← 1.30
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 순 공부 시간 라벨/값
                const Text(
                  '순 공부 시간',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  d2(data.focusTime),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16, // ← 16
                    height: 1.60, // ← 1.60
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),

                // 총 시간 라벨/값
                const Text(
                  '총 시간',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  d2(data.totalTime),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16, // ← 16
                    height: 1.60, // ← 1.60
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                // 제목 (중앙정렬)
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),

                // 목표 체크들
                ...data.goalsDone.map((g) => _GoalCheck(label: g)),

                const SizedBox(height: 10),

                // 감정(이모지 칩)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: data.moods.map((m) => _EmojiPill(label: m)).toList(),
                ),
                const SizedBox(height: 14),

                // 장소 정보
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.placeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _InfoLine(label: '공간 타입', value: data.placeType),
                              const SizedBox(width: 10),
                              _InfoLine(label: '공간 무드', value: data.placeMood),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 태그들
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.tags.map((t) => _TagPill(label: t)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtBigClock(Duration d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }
}

/// ===== 서브 위젯들 =====
class _RoundIcon extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const _RoundIcon({required this.onTap, required this.icon});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _GoalCheck extends StatelessWidget {
  final String label;
  const _GoalCheck({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.check_rounded, size: 16, color: RC.purple),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiPill extends StatelessWidget {
  final String label;
  const _EmojiPill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  const _TagPill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: RC.chip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLine({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white70, fontSize: 12),
        children: [
          TextSpan(text: '$label  ', style: const TextStyle(fontWeight: FontWeight.w500)),
          TextSpan(text: value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

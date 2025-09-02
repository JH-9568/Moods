// lib/features/record/view/record_card_preview.dart
import 'package:flutter/material.dart';

/// ===== 색상 토큰 (시안 기준) =====
class RC {
  static const purple = Color(0xFF6B6BE5);
  static const chip = Color(0xFFA7B3F1);
  static const chipStroke = Color(0xFFE8EBF8);
  static const textPrimary = Color(0xFF1B1C20);
  static const textSub = Color(0xFF9094A9);
}

/// ===== 데이터 모델 (나중에 API 연결 시 채워서 넘겨) =====
class RecordCardData {
  final DateTime date;
  final Duration focusTime;     // 순 공부 시간
  final Duration totalTime;     // 총 시간
  final String title;           // 예: "우주 이론 과목 중간고사 공부"
  final List<String> goalsDone; // 체크된 목표 목록
  final List<String> moods;     // 이모지 포함 라벨 ["😊 기쁨", "😴 졸림" ...]
  final String placeName;       // 예: "카페 칸나"
  final String placeType;       // 예: "카페"
  final String placeMood;       // 예: "소란 가끔"
  final List<String> tags;      // ["콘센트 많음","소음 높음","자리 많음"]
  final ImageProvider? background; // 카드 배경 (없으면 플레이스홀더)

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

/// ===== 라우팅/화면: 기록카드 미리보기 =====
/// 사용: Navigator.push(context, MaterialPageRoute(builder: (_) => RecordCardPreviewScreen(data: yourData)));
class RecordCardPreviewScreen extends StatelessWidget {
  final RecordCardData data;
  const RecordCardPreviewScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      '기록카드',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 카드 본체
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9/16,
                  child: _RecordCard(data: data),
                ),
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: RC.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== 단일 카드 위젯 (이미지+그라데이션+내용) =====
class _RecordCard extends StatelessWidget {
  final RecordCardData data;
  const _RecordCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bg = data.background ??
        const AssetImage('assets/images/sample_space.jpg'); // 없으면 플레이스홀더(없으면 교체 or 제거)

    // 시간 포맷
    String two(int v) => v.toString().padLeft(2, '0');
    String d2(Duration d) => '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
    final y = data.date.year.toString().padLeft(4, '0');
    final m = two(data.date.month);
    final d = two(data.date.day);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지
          DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(image: bg, fit: BoxFit.cover),
            ),
          ),
          // 어둡게 + 위/아래 그라데이션
          Container(color: Colors.black.withOpacity(0.25)),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 180,
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
              height: 220,
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
                // 상단 바: 제목 + 공유/다운로드
                Row(
                  children: [
                    const Text(
                      '기록카드',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    _RoundIcon(onTap: () {}, icon: Icons.ios_share_rounded),
                    const SizedBox(width: 8),
                    _RoundIcon(onTap: () {}, icon: Icons.download_rounded),
                  ],
                ),

                const Spacer(),

                // 날짜
                Text(
                  '$y-$m-$d',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),

                // 큰 시계 (순 공부 시간)
                FittedBox(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _fmtBigClock(data.focusTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // 총 시간
                Text(
                  '순 공부 시간',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  d2(data.totalTime),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),

                // 제목
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),

                // 목표 체크들
                ...data.goalsDone.map((g) => _GoalCheck(label: g)),

                const SizedBox(height: 10),

                // 감정(이모지 칩)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                          Text(data.placeName,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
            child: const Icon(Icons.check_rounded, size: 16, color: RC.purple),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
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

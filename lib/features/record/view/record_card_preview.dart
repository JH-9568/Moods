// lib/features/record/view/record_card_preview.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moods/common/constants/colors_j.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/record/controller/record_controller.dart';

/// 감정 → 이모지 매핑
const Map<String, String> _kEmotionEmoji = {
  '기쁨': '😆','보통': '😐','슬픔': '😭','화남': '😡','아픔': '🤢',
  '멘붕': '🤯','설렘': '😳','피곤': '😴','지루함': '🥱','애매모호': '😵‍💫',
};
const Set<String> _kEmotionSet = {
  '기쁨','보통','슬픔','화남','아픔','멘붕','설렘','피곤','지루함','애매모호',
};

class RecordCardData {
  final DateTime date;
  final Duration focusTime;
  final Duration totalTime;
  final String title;
  final List<String> goalsDone;
  final List<String> moods;
  final String placeMood;
  final String placeName;
  final String placeType;
  final List<String> tags;
  final ImageProvider? background;

  const RecordCardData({
    required this.date,
    required this.focusTime,
    required this.totalTime,
    required this.title,
    required this.goalsDone,
    required this.moods,
    required this.placeMood,
    required this.placeName,
    required this.placeType,
    required this.tags,
    this.background,
  });

  static Duration _parseHms(String? v) {
    if (v == null || v.trim().isEmpty) return Duration.zero;
    final p = v.split(':');
    if (p.length != 3) return Duration.zero;
    int toInt(String s) => int.tryParse(s) ?? 0;
    return Duration(hours: toInt(p[0]), minutes: toInt(p[1]), seconds: toInt(p[2]));
  }

  factory RecordCardData.fromRecordJson(Map<String, dynamic> rec) {
    DateTime _date(dynamic v) {
      try { return DateTime.parse(v.toString()).toLocal(); } catch (_) { return DateTime.now(); }
    }
    List _asList(dynamic v) => (v is List) ? v : const [];
    Map<String, dynamic> _asMap(dynamic v) =>
        (v is Map<String, dynamic>) ? v : (v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{});

    final title = (rec['title']?.toString() ?? '').trim();
    final date = rec['date'] != null ? _date('${rec['date']}T00:00:00') : _date(rec['end_time']);

    final focus = (rec['total_time'] != null)
        ? _parseHms(rec['total_time']?.toString())
        : (() {
            final double durSec = (rec['duration'] is num)
                ? (rec['duration'] as num).toDouble()
                : (double.tryParse(rec['duration']?.toString() ?? '') ?? 0.0);
            return Duration(milliseconds: max(0.0, durSec * 1000.0).round());
          })();
    final total = focus;

    final goalsDone = <String>[];
    for (final g in _asList(rec['goals'])) {
      final m = _asMap(g);
      final txt = m['text']?.toString().trim() ?? '';
      if (txt.isNotEmpty && m['done'] == true) goalsDone.add(txt);
    }

    List<String> emotions = _asList(rec['emotions']).map((e) => e.toString()).toList();
    if (emotions.isEmpty) {
      emotions = _asList(rec['emotion_tag_ids']).map((e) => e.toString()).toList();
      if (emotions.isEmpty) {
        emotions = _asList(rec['record_emotions']).map((e) => e.toString()).toList();
      }
    }

    Map<String, dynamic> space = _asMap(rec['space']);
    if (space.isEmpty) {
      final spaces = _asList(rec['spaces']);
      if (spaces.isNotEmpty) space = _asMap(spaces.first);
    }
    final placeName = (space['name']?.toString() ?? '').trim().isEmpty ? '미정' : space['name'].toString();
    final placeType = (space['type']?.toString() ?? '').trim().isNotEmpty
        ? space['type'].toString()
        : (_asList(space['type_tags']).isNotEmpty ? _asList(space['type_tags']).first.toString() : '공간');
    final String placeMood = (() {
      final s = (space['mood']?.toString() ?? '').trim();
      if (s.isNotEmpty) return s;
      final mt = _asList(space['mood_tags']).map((e) => e.toString()).toList().join(', ');
      return mt.isNotEmpty ? mt : '무드 미정';
    })();

    final tags = (_asList(space['tags']).isNotEmpty ? _asList(space['tags']) : _asList(rec['tags']))
        .map((e) => e.toString()).toList();

    ImageProvider? background;
    final img = rec['image_url']?.toString();
    if (img != null && img.isNotEmpty) background = NetworkImage(img);

    return RecordCardData(
      date: date,
      focusTime: focus,
      totalTime: total,
      title: title.isNotEmpty ? title : '공부 기록',
      goalsDone: goalsDone,
      moods: emotions,
      placeMood: placeMood,
      placeName: placeName,
      placeType: placeType,
      tags: tags,
      background: background,
    );
  }
}

// ───────────────────────────── Overlay ─────────────────────────────
Future<void> showRecordCardPreview(BuildContext context, RecordCardData data) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.60),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (_, __, ___) => _RecordCardOverlay(data: data),
  );
}

Future<void> showRecordCardPreviewFromRecordId(
  BuildContext context,
  WidgetRef ref,
  String recordId,
) async {
  final rec = await ref.read(recordControllerProvider.notifier).getRecordDetail(recordId);
  final data = RecordCardData.fromRecordJson(rec);
  await showRecordCardPreview(context, data);
}

class RecordCardPreviewScreen extends StatelessWidget {
  final RecordCardData data;
  const RecordCardPreviewScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.black.withOpacity(0.60), child: _RecordCardOverlay(data: data));
  }
}

class _RecordCardOverlay extends StatelessWidget {
  final RecordCardData data;
  const _RecordCardOverlay({required this.data});

  void _closeAndGoHome(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) GoRouter.of(context).go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 329,
          height: 622,
          child: _RecordCard(data: data, onConfirm: () => _closeAndGoHome(context)),
        ),
      ),
    );
  }
}

// ───────────────────────────── Card ─────────────────────────────
class _RecordCard extends StatelessWidget {
  final RecordCardData data;
  final VoidCallback onConfirm;
  const _RecordCard({required this.data, required this.onConfirm});

  (List<String> emotions, String placeMood) _normalizeEmotionsAndPlaceMood() {
    List<String> emotions = List<String>.from(data.moods);
    String placeMood = data.placeMood;

    final moodsAreEmotions = emotions.isNotEmpty && emotions.every(_kEmotionSet.contains);
    final tokens = placeMood.split(RegExp(r'[,\s]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final emotionsInPlace = tokens.where(_kEmotionSet.contains).toList();
    final nonEmotionInPlace = tokens.where((e) => !_kEmotionSet.contains(e)).toList();

    if (!moodsAreEmotions && emotionsInPlace.isNotEmpty) {
      emotions = emotionsInPlace;
      placeMood = nonEmotionInPlace.isNotEmpty ? nonEmotionInPlace.join(', ') : '무드 미정';
    }
    return (emotions, placeMood);
  }

  @override
  Widget build(BuildContext context) {
    final bg = data.background ?? const AssetImage('assets/images/sample_space.jpg');
    final (emotions, placeMoodFixed) = _normalizeEmotionsAndPlaceMood();

    String two(int v) => v.toString().padLeft(2, '0');
    String d2(Duration d) => '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
    final y = data.date.year.toString().padLeft(4, '0');
    final m = two(data.date.month);
    final d = two(data.date.day);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지 + 전체 딤(조금 더 투명)
          DecoratedBox(decoration: BoxDecoration(image: DecorationImage(image: bg, fit: BoxFit.cover))),
          Container(color: Colors.black.withOpacity(0.18)),

          // 상/하단 그라데이션(진하기 완화)
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 260,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),

          Padding(
            // 타이틀/공유/다운로드가 카드 상단에서 30px
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
            child: Column(
              children: [
                // 타이틀(중앙) + 아이콘(우측)
                SizedBox(
                  height: 36,
                  child: Stack(
                    children: [
                      Center(child: Text('기록카드', style: AppTextStyles.title.copyWith(color: Colors.white))),
                      const Positioned(
                        right: 0, top: 0, bottom: 0,
                        child: Row(
                          children: [
                            _RoundIcon(onTap: _noop, icon: Icons.ios_share_rounded),
                            SizedBox(width: 8),
                            _RoundIcon(onTap: _noop, icon: Icons.download_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 타이틀 ↔ 날짜 52px
                const SizedBox(height: 52),

                // 날짜~총시간 블록을 134px 고정.
                SizedBox(
                  height: 134,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 날짜: 맨 위
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            '$y-$m-$d',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.textR.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                      // 큰 시간: 중앙보다 위로
                      Positioned.fill(
                        child: Align(
                          alignment: const Alignment(0, -0.45),
                          child: Text(
                            d2(data.focusTime),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.time.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                      // 하단 3줄: 아래쪽에 촘촘히
                      Positioned(
                        left: 0, right: 0, bottom: 10,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('순 공부 시간',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.smallR10.copyWith(color: Colors.white, height: 1.0)),
                            const SizedBox(height: 6),
                            Text(d2(data.focusTime),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.smallSb.copyWith(color: Colors.white, height: 1.0)),
                            const SizedBox(height: 6),
                            Text('총 시간',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.smallR10.copyWith(color: Colors.white, height: 1.0)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 패널 #1 — 감정칩 하단 고정 (더 투명하게)
                Center(
                  child: _FrostedPanel(
                    width: 291,
                    height: 120,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    blurSigma: 6,
                    overlayOpacity: 0.08,
                    borderOpacity: 0.06,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 34),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  data.title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyBold.copyWith(color: Colors.white),
                                ),
                              ),
                              if (data.goalsDone.isNotEmpty) const SizedBox(height: 8),
                              ...data.goalsDone.map((g) => _GoalCheck(label: g)),
                            ],
                          ),
                        ),
                        if (emotions.isNotEmpty)
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Wrap(
                              spacing: 8, runSpacing: 8,
                              children: emotions.map((e) {
                                final emoji = _kEmotionEmoji[e] ?? '🙂';
                                return _EmojiPill(label: '$emoji  $e');
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 패널 #2 — 칩 가로 스크롤 (동일한 투명도)
                Center(
                  child: _FrostedPanel(
                    width: 291,
                    height: 112,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    blurSigma: 6,
                    overlayOpacity: 0.08,
                    borderOpacity: 0.06,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.place_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                data.placeName,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _InfoLine(label: '공간 타입', value: data.placeType),
                        const SizedBox(height: 2),
                        _InfoLine(label: '공간 무드', value: placeMoodFixed),

                        if (data.tags.isNotEmpty) const SizedBox(height: 6),
                        if (data.tags.isNotEmpty)
                          SizedBox(
                            height: 21,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  for (final t in data.tags) ...[
                                    _TagPill(label: t),
                                    const SizedBox(width: 8),
                                  ]
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 박스 ↔ 확인 버튼 22px
                const SizedBox(height: 22),

                // 확인 버튼
                SizedBox(
                  width: 297,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColorsJ.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: onConfirm,
                    child: const Text('확인', style: AppTextStyles.bodyBold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Pieces ─────────────────────────────
class _FrostedPanel extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  // ▶ 투명도/블러 조절 파라미터(기본값도 기존보다 더 투명)
  final double blurSigma;       // 기본 12 → 7
  final double overlayOpacity;  // 기본 0.15 → 0.10
  final double borderOpacity;   // 기본 0.10 → 0.06

  const _FrostedPanel({
    required this.width,
    required this.height,
    required this.child,
    this.padding,
    this.blurSigma = 7,
    this.overlayOpacity = 0.10,
    this.borderOpacity = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(15);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(overlayOpacity),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withOpacity(borderOpacity)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const _RoundIcon({required this.onTap, required this.icon});
  static void _noop() {}
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
const _noop = _RoundIcon._noop;

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
            child: const Icon(Icons.check_rounded, size: 16, color: AppColorsJ.main4),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 감정 칩 – Main2 배경, 검정 텍스트
class _EmojiPill extends StatelessWidget {
  final String label;
  const _EmojiPill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColorsJ.main2, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w600, color: AppColorsJ.black),
      ),
    );
  }
}

/// 공간 특징 칩 – Main2 배경, 검정 텍스트, 고정 높이 21 (정중앙 정렬)
class _TagPill extends StatelessWidget {
  final String label;
  const _TagPill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 21,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: AppColorsJ.main2, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTextStyles.small.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColorsJ.black,
          height: 1.0,
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
        style: AppTextStyles.small.copyWith(color: Colors.white70),
        children: [
          TextSpan(text: '$label  ', style: AppTextStyles.small.copyWith(color: Colors.white70)),
          TextSpan(text: value, style: AppTextStyles.small.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}

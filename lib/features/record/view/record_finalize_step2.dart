// lib/features/record/view/record_finalize_step2.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/features/record/controller/record_controller.dart';
import 'package:moods/features/record/view/record_card_preview.dart';

// Step1에서 공개한 공용 토큰/위젯들을 가져다 씀
import 'record_finalize_step1.dart';

class FinalizeStep2Screen extends ConsumerStatefulWidget {
  const FinalizeStep2Screen({super.key});
  @override
  ConsumerState<FinalizeStep2Screen> createState() => _FinalizeStep2ScreenState();
}

class _FinalizeStep2ScreenState extends ConsumerState<FinalizeStep2Screen> {
  final _titleCtrl = TextEditingController();
  final _spaceCtrl = TextEditingController();

  final Set<String> _selectedEmotions = {};
  final Set<String> _selectedPlaceTags = {};

  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _spaceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(recordControllerProvider);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.sheetTop,
        elevation: 0,
        centerTitle: true,
        title: const Text('기록하기',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            const Text('기록할 정보를',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const Text('입력해 주세요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),

            const FieldLabel('제목'),
            const SizedBox(height: 8),
            InputBox.text(controller: _titleCtrl, hint: '제목 입력'),

            const SizedBox(height: 18),
            const FieldLabel('감정'),
            const SizedBox(height: 2),
            const Text('공부할 때 어떤 감정을 느꼈나요?',
                style: TextStyle(fontSize: 12, color: C.textSub)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: EMOTION_TAGS.map((e) {
                final on = _selectedEmotions.contains(e);
                return ChoiceChip(
                  label: Text(
                    e,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: on ? Colors.white : C.textMain,
                    ),
                  ),
                  selected: on,
                  onSelected: (_) {
                    setState(() {
                      on ? _selectedEmotions.remove(e) : _selectedEmotions.add(e);
                    });
                  },
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: C.purpleSoft,
                  side: const BorderSide(color: C.chipStroke),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: const StadiumBorder(),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 고스트 이미지 피커 (카메라/갤러리 콜백은 나중에 연결)
            const GhostImagePicker(),

            const SizedBox(height: 20),
            const FieldLabel('공간'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: C.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: C.chipStroke),
                    ),
                  ),
                  onPressed: () {
                    // TODO: 지도에서 선택 페이지로 이동
                  },
                  child: const Text('지도에서 선택',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InputBox.text(controller: _spaceCtrl, hint: '직접 입력'),

            const SizedBox(height: 20),
            const FieldLabel('공간 특징'),
            const SizedBox(height: 2),
            const Text('공부에 도움되는 공간의 특징을 정리해보세요.',
                style: TextStyle(fontSize: 12, color: C.textSub)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: PLACE_FEATURES.map((t) {
                final on = _selectedPlaceTags.contains(t);
                return ChoiceChip(
                  label: Text(
                    t,
                    style: TextStyle(
                      fontSize: 14,
                      color: on ? Colors.white : C.textMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: on,
                  onSelected: (_) {
                    setState(() {
                      on ? _selectedPlaceTags.remove(t) : _selectedPlaceTags.add(t);
                    });
                  },
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: C.purpleSoft,
                  side: const BorderSide(color: C.chipStroke),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: const StadiumBorder(),
                );
              }).toList(),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: S.h48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _submitting ? C.purple.withOpacity(.6) : C.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      try {
                        // 1) finalize 메타 → 컨트롤러에 반영
                        ref.read(recordControllerProvider.notifier).applyFinalizeMeta(
                              title: _titleCtrl.text.trim().isEmpty
                                  ? '공부 기록'
                                  : _titleCtrl.text.trim(),
                              emotionTagIds: _selectedEmotions.toList(),
                              spaceId: _spaceCtrl.text.trim(),
                            );

                        // 2) 서버 export
                        final resp = await ref
                            .read(recordControllerProvider.notifier)
                            .exportToRecord();

                        final ok = resp['success'] == true;
                        final data = (resp['data'] is Map<String, dynamic>)
                            ? resp['data'] as Map<String, dynamic>
                            : <String, dynamic>{};
                        if (!ok || data.isEmpty) {
                          throw Exception('서버 응답이 올바르지 않습니다: $resp');
                        }

                        // ── 파싱
                        final String title =
                            (data['title']?.toString() ?? '').trim();
                        final double durSec = (data['duration'] is num)
                            ? (data['duration'] as num).toDouble()
                            : double.tryParse('${data['duration']}') ?? 0.0;

                        DateTime? _iso(v) {
                          try { return DateTime.parse('$v').toLocal(); }
                          catch (_) { return null; }
                        }

                        final endedAt = _iso(data['end_time']) ?? DateTime.now();
                        final startedAt = _iso(data['start_time']) ??
                            endedAt.subtract(Duration(milliseconds: (durSec * 1000).round()));

                        final goalsDone =
                            (data['goals'] is List ? data['goals'] as List : const [])
                                .whereType<Map>()
                                .where((g) => g['done'] == true)
                                .map((g) => (g['text'] ?? '').toString())
                                .where((s) => s.isNotEmpty)
                                .toList();

                        List<String> _toStrList(v) {
                          if (v is List) return v.map((e) => e.toString()).toList();
                          if (v is String && v.isNotEmpty) return [v];
                          return const <String>[];
                        }

                        final moods = _toStrList(data['mood_id']);
                        final emotionTags = _toStrList(data['emotion_tag_ids']);
                        final spaceId = (data['space_id']?.toString() ?? '');

                        final focus = Duration(
                            milliseconds: max(0, (durSec * 1000).round()));

                        if (!mounted) return;
                        Navigator.pop(context); // step2 닫기
                        Navigator.pop(context); // step1 닫기

                        final st2 = ref.read(recordControllerProvider);
                        final bgProvider = (st2.wallpaperUrl.trim().isNotEmpty)
                            ? NetworkImage(st2.wallpaperUrl)
                            : null;

                        final dataForPreview = RecordCardData(
                          date: endedAt,
                          focusTime: focus,
                          totalTime: endedAt.difference(startedAt).isNegative
                              ? focus
                              : endedAt.difference(startedAt),
                          title: title.isNotEmpty
                              ? title
                              : st2.title.isNotEmpty ? st2.title : '공부 기록',
                          goalsDone: goalsDone,
                          moods: moods.isNotEmpty ? moods : st2.selectedMoods,
                          placeName: spaceId.isNotEmpty ? spaceId : '미정',
                          placeType: '공간',
                          placeMood: emotionTags.isNotEmpty
                              ? emotionTags.join(', ')
                              : '무드 미정',
                          tags: _selectedPlaceTags.toList(),
                          background: bgProvider,
                        );

                        // 미리보기 라우트로
                        if (mounted) {
                          // context.push('/record/preview', extra: dataForPreview);
                          // 사용 중인 라우터에 맞게 호출 (위 주석 유지)
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('생성 실패: $e')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
              child: const Text('기록카드 생성하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

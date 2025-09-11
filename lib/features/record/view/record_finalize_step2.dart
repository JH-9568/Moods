// lib/features/record/view/record_finalize_step2.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:moods/features/record/controller/record_controller.dart';
import 'package:moods/features/record/view/record_card_preview.dart';
import 'package:moods/features/record/view/map_view.dart';

/// =======================
/// Step2 전용 토큰 (Step1과 톤 맞춤)
/// =======================
class C {
  static const bg = Color(0xFFF3F5FF);
  static const sheetTop = Colors.white;
  static const surface = Colors.white;
  static const chipStroke = Color(0xFFE5E7F4);
  static const primarySoft = Color(0xFFA7B3F1);
  static const primaryDeep = Color(0xFF6E6BF0);
  static const textMain = Color(0xFF111318);
  static const textSub = Color(0xFF8C90A4);
}

/// =======================
/// 로컬 상수 (감정/공간태그)
/// =======================
const _EMOTION_TAGS = <String>[
  '기쁨', '보통', '슬픔', '화남', '아픔', '멘붕', '졸림', '피곤', '지루함', '애매모호',
];

const _PLACE_FEATURES = <String>[
  '콘센트 많음', '와이파이 퀄리티 좋음', '소음 높음', '소음 낮음', '자리 많음',
];

/// =======================
/// Step2 화면
/// =======================
class FinalizeStep2Screen extends ConsumerStatefulWidget {
  const FinalizeStep2Screen({super.key});
  @override
  ConsumerState<FinalizeStep2Screen> createState() =>
      _FinalizeStep2ScreenState();
}

class _FinalizeStep2ScreenState extends ConsumerState<FinalizeStep2Screen> {
  final _titleCtrl = TextEditingController();
  final _spaceCtrl = TextEditingController(); // 사용자에게 보일 장소명

  /// 지도에서 고른 Google Place ID (서버로 보낼 값)
  String? _selectedSpaceId;

  final Set<String> _selectedEmotions = {};
  final Set<String> _selectedPlaceTags = {};
  bool _submitting = false;

  // image_picker 상태
  XFile? _image;
  final ImagePicker picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _image = pickedFile);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 가져오는데 실패했습니다: $e')),
      );
    }
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_image!.path),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () => setState(() => _image = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _spaceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st   = ref.watch(recordControllerProvider);
    final ctrl = ref.read(recordControllerProvider.notifier);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.sheetTop,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '기록하기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _submitting
              ? null
              : () async {
                  final quit = await _showQuitConfirmDialog(context);
                  if (quit == true) {
                    final ok = await ctrl.quit(context: context);
                    if (ok && mounted) {
                      context.go('/home');
                    }
                  }
                },
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

            const _FieldLabel('제목'),
            const SizedBox(height: 8),
            _InputBox.text(controller: _titleCtrl, hint: '제목 입력'),

            const SizedBox(height: 18),
            const _FieldLabel('감정'),
            const SizedBox(height: 2),
            const Text(
              '공부할 때 어떤 감정을 느꼈나요?',
              style: TextStyle(fontSize: 12, color: C.textSub),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _EMOTION_TAGS.map((e) {
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
                  selectedColor: C.primarySoft,
                  side: const BorderSide(color: C.chipStroke),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: const StadiumBorder(),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 이미지 피커
            _image == null
                ? _GhostImagePicker(
                    onCameraTap: () => _pickImage(ImageSource.camera),
                    onGalleryTap: () => _pickImage(ImageSource.gallery),
                  )
                : _buildImagePreview(),

            const SizedBox(height: 20),
            const _FieldLabel('공간'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: C.primaryDeep,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: C.chipStroke),
                    ),
                  ),
                  onPressed: () async {
                    final picked = await Navigator.push<SelectedPlace>(
                      context,
                      MaterialPageRoute(builder: (_) => const MapSelectPage()),
                    );
                    if (picked != null) {
                      setState(() {
                        _spaceCtrl.text  = picked.name;     // 화면 표시용
                        _selectedSpaceId = picked.placeId;  // 서버 전송용
                      });
                    }
                  },
                  child: const Text('지도에서 선택',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 장소 입력칸(읽기전용: 지도로만 선택)
            _InputBox.text(
              controller: _spaceCtrl,
              hint: '지도로 선택하세요',
              readOnly: true,
            ),

            const SizedBox(height: 20),
            const _FieldLabel('공간 특징'),
            const SizedBox(height: 2),
            const Text(
              '공부에 도움되는 공간의 특징을 정리해보세요.',
              style: TextStyle(fontSize: 12, color: C.textSub),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: _PLACE_FEATURES.map((t) {
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
                  selectedColor: C.primarySoft,
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
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _submitting ? C.primaryDeep.withOpacity(.6) : C.primaryDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      try {
                        // 공간 선택 안했으면 막기
                        if (_selectedSpaceId == null ||
                            _selectedSpaceId!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('지도를 열어 공간을 선택해 주세요.')),
                          );
                          return;
                        }

                        // 1) finalize 메타 저장 (spaceId에 place_id 넣음)
                        ref.read(recordControllerProvider.notifier).applyFinalizeMeta(
                          title: _titleCtrl.text.trim().isEmpty
                              ? '공부 기록'
                              : _titleCtrl.text.trim(),
                          emotionTagIds: _selectedEmotions.toList(),
                          spaceId: _selectedSpaceId!, // ⭐ 서버로 가는 값
                        );

                        debugPrint('[Finalize] _selectedSpaceId=$_selectedSpaceId  uiName=${_spaceCtrl.text}');


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

                        final endedAt =
                            _iso(data['end_time']) ?? DateTime.now();
                        final startedAt = _iso(data['start_time']) ??
                            endedAt.subtract(
                              Duration(milliseconds: (durSec * 1000).round()),
                            );

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

                        final moods       = _toStrList(data['mood_id']);
                        final emotionTags = _toStrList(data['emotion_tag_ids']);

                        final focus = Duration(
                          milliseconds: max(0, (durSec * 1000).round()),
                        );

                        if (!mounted) return;

                        final st2 = ref.read(recordControllerProvider);

                        // 배경: 선택 이미지 > 세션 배경
                        final ImageProvider? bgProvider =
                            _image != null
                                ? FileImage(File(_image!.path))
                                : (st2.wallpaperUrl.trim().isNotEmpty
                                    ? NetworkImage(st2.wallpaperUrl)
                                    : null);

                        final dataForPreview = RecordCardData(
                          date: endedAt,
                          focusTime: focus,
                          totalTime: endedAt.difference(startedAt).isNegative
                              ? focus
                              : endedAt.difference(startedAt),
                          title: title.isNotEmpty
                              ? title
                              : st2.title.isNotEmpty
                                  ? st2.title
                                  : '공부 기록',
                          goalsDone: goalsDone,
                          moods: moods.isNotEmpty ? moods : st2.selectedMoods,
                          placeName: _spaceCtrl.text.trim().isNotEmpty
                              ? _spaceCtrl.text.trim()
                              : '미정', // 카드에는 보기 좋은 이름 노출
                          placeType: '공간',
                          placeMood: emotionTags.isNotEmpty
                              ? emotionTags.join(', ')
                              : '무드 미정',
                          tags: _selectedPlaceTags.toList(),
                          background: bgProvider,
                        );

                        await showRecordCardPreview(context, dataForPreview);
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
              child: const Text(
                '기록카드 생성하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 확인 다이얼로그
Future<bool?> _showQuitConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: const Text(
        '지금 나가면\n기록이 저장되지 않아요',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C.textMain),
      ),
      content: const Text(
        '이어서 기록을 저장하시겠어요?',
        style: TextStyle(fontSize: 14, color: C.textSub),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: C.primaryDeep,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('네\n기록을 저장할래요', textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: C.chipStroke),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: C.textMain,
              backgroundColor: C.surface,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('아니요\n나갈래요', textAlign: TextAlign.center),
          ),
        ),
      ],
    ),
  );
}

/// =======================
/// 로컬 파츠
/// =======================
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: C.textMain,
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool readOnly;

  const _InputBox.text({
    required this.controller,
    required this.hint,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.chipStroke),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintStyle: TextStyle(color: C.textSub),
        ).copyWith(hintText: hint),
      ),
    );
  }
}

class _GhostImagePicker extends StatelessWidget {
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;

  const _GhostImagePicker({this.onCameraTap, this.onGalleryTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEDEFFF),
            border: Border.all(color: C.chipStroke),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '공간을 함께 저장해보세요',
                style: TextStyle(
                    color: C.textMain, fontWeight: FontWeight.w600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GhostIconBtn(
                    icon: Icons.photo_camera_outlined,
                    label: '카메라',
                    onTap: onCameraTap,
                  ),
                  const SizedBox(width: 20),
                  _GhostIconBtn(
                    icon: Icons.photo_library_outlined,
                    label: '갤러리',
                    onTap: onGalleryTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostIconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _GhostIconBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.chipStroke),
            ),
            child: Icon(icon, size: 28, color: C.primaryDeep),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
                fontSize: 13, color: C.textSub, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

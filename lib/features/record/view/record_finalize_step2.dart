// lib/features/record/view/record_finalize_step2.dart
// ─────────────────────────────────────────────────────────────────────────────
// Step2: 기록 메타 입력 화면 (리팩토링 버전)
// - 디자인/동작 동일
// - 섹션/위젯/유틸로 깔끔하게 분리
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:moods/features/record/controller/record_controller.dart';
import 'package:moods/features/record/view/record_card_preview.dart';
import 'package:moods/features/record/view/map_view.dart';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║ 1) TOKENS & CONSTANTS                                                    ║
// ╚══════════════════════════════════════════════════════════════════════════╝

/// 레이아웃 상수
class Dimens {
  static const bodyHPad = 24.0;
  static const bodyTopPad = 28.0;
  static const headerFontSize = 22.0;
  static const headerWeight = FontWeight.w700;

  // 감정 칩 간격
  static const emotionGapH = 8.0;
  static const emotionGapV = 10.0;
}

/// Step2 전용 컬러 토큰
class C2 {
  static const bg = Color(0xFFF3F5FF);
  static const sheetTop = Colors.white;
  static const surface = Colors.white;
  static const chipStroke = Color(0xFFE5E7F4);
  static const primarySoft = Color(0xFFA7B3F1);
  static const primaryDeep = Color(0xFF6E6BF0);
  static const textMain = Color(0xFF111318);
  static const textSub = Color(0xFF8C90A4);
}

/// 감정/태그 고정 리스트
const _EMOTION_TAGS = <String>[
  '기쁨', '보통', '슬픔', '화남', '아픔', '멘붕', '설렘', '피곤', '지루함', '애매모호',
];

const _EMOJI = <String, String>{
  '기쁨': '😆',
  '보통': '😐',
  '슬픔': '😭',
  '화남': '😡',
  '아픔': '🤢',
  '멘붕': '🤯',
  '설렘': '😳',
  '피곤': '😴',
  '지루함': '🥱',
  '애매모호': '😵‍💫',
};

const _PLACE_FEATURES = <String>[
  '콘센트 많음', '와이파이 퀄리티 좋음', '소음 높음', '소음 낮음', '자리 많음',
];

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║ 2) SCREEN                                                                ║
// ╚══════════════════════════════════════════════════════════════════════════╝

class FinalizeStep2Screen extends ConsumerStatefulWidget {
  const FinalizeStep2Screen({super.key});
  @override
  ConsumerState<FinalizeStep2Screen> createState() =>
      _FinalizeStep2ScreenState();
}

class _FinalizeStep2ScreenState extends ConsumerState<FinalizeStep2Screen> {
  // ── form state ────────────────────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _spaceCtrl = TextEditingController();
  String? _selectedSpaceId;

  final Set<String> _selectedEmotions = {};
  final Set<String> _selectedPlaceTags = {};
  bool _submitting = false;

  // ── image state ───────────────────────────────────────────────────────────
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _titleCtrl.dispose();
    _spaceCtrl.dispose();
    super.dispose();
  }

  // ── actions ───────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) setState(() => _image = pickedFile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 가져오는데 실패했습니다: $e')),
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      if (_selectedSpaceId == null || _selectedSpaceId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지도를 열어 공간을 선택해 주세요.')),
        );
        return;
      }

      final notifier = ref.read(recordControllerProvider.notifier);
      notifier.applyFinalizeMeta(
        title: _titleCtrl.text.trim().isEmpty ? '공부 기록' : _titleCtrl.text.trim(),
        emotionTagIds: _selectedEmotions.toList(),
        spaceId: _selectedSpaceId!,
      );

      final resp = await notifier.exportToRecord();
      final ok = resp['success'] == true;
      final data = (resp['data'] is Map<String, dynamic>)
          ? resp['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      if (!ok || data.isEmpty) {
        throw Exception('서버 응답이 올바르지 않습니다: $resp');
      }

      // ── 데이터 파싱
      String title = (data['title']?.toString() ?? '').trim();
      final double durSec = (data['duration'] is num)
          ? (data['duration'] as num).toDouble()
          : double.tryParse('${data['duration']}') ?? 0.0;

      DateTime? _iso(v) {
        try {
          return DateTime.parse('$v').toLocal();
        } catch (_) {
          return null;
        }
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
      final focus = Duration(milliseconds: max(0, (durSec * 1000).round()));

      final st2 = ref.read(recordControllerProvider);
      final ImageProvider? bgProvider = _image != null
          ? FileImage(File(_image!.path))
          : (st2.wallpaperUrl.trim().isNotEmpty
              ? NetworkImage(st2.wallpaperUrl)
              : null);

      final preview = RecordCardData(
        date: endedAt,
        focusTime: focus,
        totalTime: endedAt.difference(startedAt).isNegative
            ? focus
            : endedAt.difference(startedAt),
        title: title.isNotEmpty ? title : (st2.title.isNotEmpty ? st2.title : '공부 기록'),
        goalsDone: goalsDone,
        moods: moods.isNotEmpty ? moods : st2.selectedMoods,
        placeName: _spaceCtrl.text.trim().isNotEmpty ? _spaceCtrl.text.trim() : '미정',
        placeType: '공간',
        placeMood: emotionTags.isNotEmpty ? emotionTags.join(', ') : '무드 미정',
        tags: _selectedPlaceTags.toList(),
        background: bgProvider,
      );

      await showRecordCardPreview(context, preview);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('생성 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── UI builders (섹션별) ───────────────────────────────────────────────────
  Widget _sectionHeader() => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기록할 정보를',
            style: TextStyle(
              fontSize: Dimens.headerFontSize,
              fontWeight: Dimens.headerWeight,
              color: C2.textMain,
            ),
          ),
          Text(
            '입력해 주세요',
            style: TextStyle(
              fontSize: Dimens.headerFontSize,
              fontWeight: Dimens.headerWeight,
              color: C2.textMain,
            ),
          ),
        ],
      );

  Widget _sectionTitleInput() => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('제목'),
          SizedBox(height: 8),
        ],
      );

  Widget _sectionEmotion() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('감정'),
          const SizedBox(height: 2),
          const Text(
            '공부할 때 어떤 감정을 느꼈나요?',
            style: TextStyle(fontSize: 12, color: C2.textSub),
          ),
          const SizedBox(height: 12),
          _EmotionGrid(
            tags: _EMOTION_TAGS,
            selected: _selectedEmotions,
            onToggle: (e) {
              setState(() {
                _selectedEmotions.contains(e)
                    ? _selectedEmotions.remove(e)
                    : _selectedEmotions.add(e);
              });
            },
          ),
        ],
      );

  Widget _sectionImagePicker() => _image == null
      ? _GhostImagePicker(
          onCameraTap: () => _pickImage(ImageSource.camera),
          onGalleryTap: () => _pickImage(ImageSource.gallery),
        )
      : _ImagePreview(path: _image!.path, onClear: () => setState(() => _image = null));

  Widget _sectionSpacePicker() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('공간'),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: C2.primaryDeep,
                  foregroundColor: Colors.white,
                  fixedSize: const Size(120, 40), // 너비를 120으로 늘려 줄바꿈 방지
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final picked = await Navigator.push<SelectedPlace>(
                    context,
                    MaterialPageRoute(builder: (_) => const MapSelectPage()),
                  );
                  if (picked != null) {
                    setState(() {
                      _spaceCtrl.text = picked.name;
                      _selectedSpaceId = picked.placeId;
                    });
                  }
                },
                child: const Text('지도에서 선택', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InputBox.text(controller: _spaceCtrl, hint: '지도로 선택하세요', readOnly: true),
        ],
      );

  Widget _sectionPlaceFeatures() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('공간 특징'),
          const SizedBox(height: 2),
          const Text(
            '공부에 도움되는 공간의 특징을 정리해보세요.',
            style: TextStyle(fontSize: 12, color: C2.textSub),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _PLACE_FEATURES.map((t) {
              final on = _selectedPlaceTags.contains(t);
              return ChoiceChip(
                label: Text(
                  t,
                  style: TextStyle(
                    fontSize: 14,
                    color: on ? Colors.white : C2.textMain,
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
                selectedColor: C2.primarySoft,
                side: const BorderSide(color: C2.chipStroke),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: const StadiumBorder(),
              );
            }).toList(),
          ),
        ],
      );

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // st, ctrl는 리스너 목적으로 남겨둠(동작 동일)
    final st = ref.watch(recordControllerProvider);
    final ctrl = ref.read(recordControllerProvider.notifier);

    return Scaffold(
      backgroundColor: C2.bg,
      appBar: AppBar(
        backgroundColor: C2.sheetTop,
        elevation: 0,
        centerTitle: true,
        title: const Text('기록하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _submitting
              ? null
              : () async {
                  final quit = await _showQuitConfirmDialog(context);
                  if (quit == true) {
                    final ok = await ctrl.quit(context: context);
                    if (ok && mounted) context.go('/home');
                  }
                },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Dimens.bodyHPad, Dimens.bodyTopPad, Dimens.bodyHPad, 16,
          ),
          children: [
            // ── Header
            _sectionHeader(),
            const SizedBox(height: 22),

            // ── 제목
            _sectionTitleInput(),
            _InputBox.text(controller: _titleCtrl, hint: '제목 입력'),

            const SizedBox(height: 18),

            // ── 감정
            _sectionEmotion(),

            const SizedBox(height: 18),

            // ── 이미지 피커
            _sectionImagePicker(),

            const SizedBox(height: 20),

            // ── 공간 선택/입력
            _sectionSpacePicker(),

            const SizedBox(height: 20),

            // ── 공간 특징
            _sectionPlaceFeatures(),

            const SizedBox(height: 90),
          ],
        ),
      ),

      // ── 하단 제출 버튼
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _submitting ? C2.primaryDeep.withOpacity(.6) : C2.primaryDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitting ? null : _submit,
              child: const Text('기록카드 생성하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║ 3) DIALOGS                                                               ║
// ╚══════════════════════════════════════════════════════════════════════════╝

Future<bool?> _showQuitConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      title: const Text(
        '지금 나가면\n기록이 저장되지 않아요',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: C2.textMain),
      ),
      content: const Text(
        '이어서 기록을 저장하시겠어요?',
        style: TextStyle(fontSize: 14, color: C2.textSub),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: C2.primaryDeep,
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
              side: const BorderSide(color: C2.chipStroke),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: C2.textMain,
              backgroundColor: C2.surface,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('아니요\n나갈래요', textAlign: TextAlign.center),
          ),
        ),
      ],
    ),
  );
}

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║ 4) REUSABLE WIDGETS                                                      ║
// ╚══════════════════════════════════════════════════════════════════════════╝

/// 감정 그리드(4열 고정, 좌우대칭, 이모지 포함)
class _EmotionGrid extends StatelessWidget {
  const _EmotionGrid({
    required this.tags,
    required this.selected,
    required this.onToggle,
    this.columns = 4,
  });

  final List<String> tags;
  final Set<String> selected;
  final void Function(String tag) onToggle;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final totalW = c.maxWidth;
        final gap = Dimens.emotionGapH;
        final itemW = (totalW - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: Dimens.emotionGapV,
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.center,
          children: tags.map((t) {
            double currentItemW;
            if (t == '지루함') {
              currentItemW = 88.0;
            } else if (t == '애매모호') {
              currentItemW = 102.0;
            } else {
              currentItemW = itemW;
            }

            return SizedBox(
              width: currentItemW,
              child: _EmotionChipFixed(
                label: t,
                emoji: _EMOJI[t] ?? '🙂',
                selected: selected.contains(t),
                onTap: () => onToggle(t),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// 고정 너비 감정 칩(이모지 + 텍스트)
class _EmotionChipFixed extends StatelessWidget {
  const _EmotionChipFixed({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? C2.primarySoft : Colors.white;
    final fg = selected ? Colors.white : C2.textMain;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: C2.chipStroke),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C2.textMain),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox.text({
    required this.controller,
    required this.hint,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: C2.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C2.chipStroke),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintStyle: TextStyle(color: C2.textSub),
        ).copyWith(hintText: hint),
      ),
    );
  }
}

/// 이미지 미리보기
class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.path, required this.onClear});

  final String path;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: onClear,
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
}

/// “공간을 함께 저장해보세요” — 329×130(오버플로우 해결)
class _GhostImagePicker extends StatelessWidget {
  const _GhostImagePicker({this.onCameraTap, this.onGalleryTap});

  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // 화면 너비에 맞게 확장
      height: 130,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEDEFFF),
            border: Border.all(color: C2.chipStroke),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column( // 텍스트와 버튼 그룹 전체를 세로 중앙에 배치
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '공간을 함께 저장해보세요',
                style: TextStyle(
                  color: C2.textMain,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8), // 텍스트와 버튼 사이의 간격 유지
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GhostIconBtn(
                    assetPath: 'assets/fonts/icons/mdi_camera.svg',
                    label: '카메라',
                    onTap: onCameraTap,
                  ),
                  const SizedBox(width: 20),
                  _GhostIconBtn(
                    assetPath: 'assets/fonts/icons/gallery.svg',
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
  const _GhostIconBtn({required this.assetPath, required this.label, this.onTap});

  final String assetPath;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SvgPicture.asset(
          assetPath,
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(C2.primaryDeep, BlendMode.srcIn),
        ),
      ),
    );
  }
}

// lib/features/record/view/record_finalize_step2.dart
// ─────────────────────────────────────────────────────────────────────────────
// Step2: 기록 메타 입력 화면 (리팩토링 + 사진 업로드 UI 연결 + 상세값 적용)
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
import 'package:moods/common/constants/colors_j.dart';
import 'package:moods/common/constants/text_styles.dart';

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

/// export 응답에서 record_id 추출
String _recordIdFromResp(Map<String, dynamic> resp) {
  Map<String, dynamic> asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  final root = asMap(resp);
  final data = asMap(root['data']);
  final record = asMap(root['record'] ?? data['record']);

  final dynamic idAny =
      record['id'] ??
      record['record_id'] ??
      data['id'] ??
      data['record_id'] ??
      root['id'] ??
      root['record_id'];

  final id = idAny?.toString() ?? '';
  if (id.isEmpty) throw Exception('export 응답에 record_id가 없습니다.');
  return id;
}

// 리스트나 문자열을 ", "로 합치기
String _joinTags(dynamic v) {
  if (v == null) return '';
  if (v is List) {
    return v
        .map((e) => e is Map ? (e['name']?.toString() ?? e.toString()) : e.toString())
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
  }
  return v.toString();
}

// ╔══════════════════════════════════════════════════════════════════════════╗
/* 2) SCREEN */
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
  bool _uploading = false; // 업로드 진행 상태

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _titleCtrl.dispose();
    _spaceCtrl.dispose();
    super.dispose();
  }

  // ── actions ───────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
  if (_uploading) return;
  try {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 92);
    if (pickedFile == null) return;

    // 미리보기만 표시
    if (!mounted) return;
    setState(() {
      _image = pickedFile;
      _uploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('사진이 선택되었습니다. 생성 시 함께 업로드됩니다.')),
    );
  } catch (e) {
    if (!mounted) return;
    setState(() => _uploading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('사진 선택 실패: $e')),
    );
  }
}


Future<void> _submit() async {
  setState(() => _submitting = true);
  try {
    // 공간 필수
    if (_selectedSpaceId == null || _selectedSpaceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도를 열어 공간을 선택해 주세요.')),
      );
      return;
    }

    // ─────────────────────────────────────────────
    // 공간특징 칩 → API 필드로 매핑
    // ─────────────────────────────────────────────
    final bool power = _selectedPlaceTags.contains('콘센트 많음');

    // 와이파이 퀄리티가 좋음이면 스코어 4로 가정(스펙에 맞게 조정 가능)
    final int? wifiScore =
        _selectedPlaceTags.contains('와이파이 퀄리티 좋음') ? 4 : null;

    // 소음: 낮음=1, 보통=2, 높음=3 (둘 다 선택되면 충돌 → 2로 강제)
    int? noiseLevel;
    final bool noiseLow = _selectedPlaceTags.contains('소음 낮음');
    final bool noiseHigh = _selectedPlaceTags.contains('소음 높음');
    if (noiseLow && !noiseHigh) {
      noiseLevel = 1;
    } else if (!noiseLow && noiseHigh) {
      noiseLevel = 3;
    } else if (noiseLow && noiseHigh) {
      noiseLevel = 2; // 충돌 시 보통 처리
    } else {
      noiseLevel = null; // 미선택이면 서버 기본값 사용
    }

    // 혼잡도: 자리 많음이면 여유=1 (그 외 미선택이면 null)
    final int? crowdness =
        _selectedPlaceTags.contains('자리 많음') ? 1 : null;

    final notifier = ref.read(recordControllerProvider.notifier);

    // 화면 메타 로컬 반영 + 서버로 보낼 값
    notifier.applyFinalizeMeta(
      title: _titleCtrl.text.trim().isEmpty ? '공부 기록' : _titleCtrl.text.trim(),
      emotionTagIds: _selectedEmotions.toList(), // 서버가 라벨 받는 스펙
      spaceId: _selectedSpaceId!,
      // ↓↓↓ 공간특징 필드 추가
      wifiScore: wifiScore,
      noiseLevel: noiseLevel,
      crowdness: crowdness,
      power: power,
    );

    // 1) 기록 생성
    final resp = await notifier.exportToRecord();
    final ok = resp['success'] == true;
    if (!ok) throw Exception('서버 응답이 올바르지 않습니다: $resp');

    // 2) record_id
    final recordId = _recordIdFromResp(resp);

    // 3) 사진 업로드(있으면)
    if (_image != null) {
      try {
        await notifier.uploadRecordPhoto(recordId, File(_image!.path));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 업로드 실패: $e')),
        );
      }
    }

    // 4) 현재 state 값으로 미리보기 (서버 재조회 대신)
    final currentState = ref.read(recordControllerProvider);
    // 공간 이름은 컨트롤러 state에 없으므로, 텍스트 필드에서 직접 가져옴
    final spaceDetailForPreview = {'name': _spaceCtrl.text};
    final cardData = RecordCardData.fromRecordState(currentState, spaceDetailForPreview);
    await showRecordCardPreview(context, cardData);

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
              color: AppColorsJ.black,
            ),
          ),
          Text(
            '입력해 주세요',
            style: TextStyle(
              fontSize: Dimens.headerFontSize,
              fontWeight: Dimens.headerWeight,
              color: AppColorsJ.black,
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
            style: TextStyle(fontSize: 12, color: AppColorsJ.gray6),
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

  Widget _sectionImagePicker() {
    if (_image == null) {
      return _GhostImagePicker(
        onCameraTap: _uploading ? null : () => _pickImage(ImageSource.camera),
        onGalleryTap: _uploading ? null : () => _pickImage(ImageSource.gallery),
      );
    }

    // 미리보기 + 업로드 로딩 오버레이
    return Stack(
      children: [
        _ImagePreview(
          path: _image!.path,
          onClear: _uploading ? () {} : () => setState(() => _image = null),
        ),
        if (_uploading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black38,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

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
                  backgroundColor: AppColorsJ.main3,
                  foregroundColor: Colors.white,
                  fixedSize: const Size(120, 40),
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
                child: const Text('지도에서 선택',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
            style: TextStyle(fontSize: 12, color: AppColorsJ.gray6),
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
                    color: on ? Colors.white : AppColorsJ.black,
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
                selectedColor: AppColorsJ.main3,
                side: const BorderSide(color: AppColorsJ.main2),
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
    final st = ref.watch(recordControllerProvider);
    final ctrl = ref.read(recordControllerProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: AppColorsJ.main1,
      appBar: AppBar(
        backgroundColor: AppColorsJ.main1,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: SizedBox(height: 1.0, child: ColoredBox(color: AppColorsJ.main2)),
        ),
        centerTitle: true,
        title: const Text(
          '기록하기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColorsJ.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColorsJ.black),
          onPressed: (_submitting || _uploading)
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Dimens.bodyHPad, Dimens.bodyTopPad, Dimens.bodyHPad, 16,
        ),
        children: [
          _sectionHeader(),
          const SizedBox(height: 22),
          _sectionTitleInput(),
          _InputBox.text(controller: _titleCtrl, hint: '제목 입력'),
          const SizedBox(height: 18),
          _sectionEmotion(),
          const SizedBox(height: 18),
          _sectionImagePicker(),
          const SizedBox(height: 20),
          _sectionSpacePicker(),
          const SizedBox(height: 20),
          _sectionPlaceFeatures(),
          const SizedBox(height: 90),
        ],
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
                    (_submitting || _uploading) ? AppColorsJ.gray3Normal : AppColorsJ.main3,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: (_submitting || _uploading) ? null : _submit,
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

// ╔══════════════════════════════════════════════════════════════════════════╗
/* 3) DIALOGS  — Step1 과 동일 스타일 */
// ╚══════════════════════════════════════════════════════════════════════════╝

Future<bool?> _showQuitConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _QuitDialog(),
  );
}

class _QuitDialog extends StatelessWidget {
  const _QuitDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColorsJ.gray2,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '지금 나가면\n기록이 저장되지 않아요',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 6),
            Text(
              '기록을 저장하시겠어요?',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColorsJ.black),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: _DialogBigButton(
                    bg: AppColorsJ.main3,
                    top: '네',
                    bottom: '기록을 저장할게요',
                    isQuit: false,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _DialogBigButton(
                    bg: AppColorsJ.gray4,
                    top: '아니요',
                    bottom: '나갈게요',
                    isQuit: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogBigButton extends StatelessWidget {
  final Color bg;
  final String top, bottom;
  final bool isQuit;

  const _DialogBigButton({
    required this.bg,
    required this.top,
    required this.bottom,
    required this.isQuit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        onPressed: () => Navigator.of(context).pop(isQuit),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              top,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyBold.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              bottom,
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
/* 4) REUSABLE WIDGETS */
// ╚══════════════════════════════════════════════════════════════════════════╝

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
    final bg = selected ? AppColorsJ.main3 : Colors.white;
    final fg = selected ? Colors.white : AppColorsJ.black;

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
            border: Border.all(color: AppColorsJ.main2),
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
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColorsJ.black),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColorsJ.main2),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintStyle: TextStyle(color: AppColorsJ.grayText),
        ).copyWith(hintText: hint),
      ),
    );
  }
}

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

/// “공간을 함께 저장해보세요” — 329×130
class _GhostImagePicker extends StatelessWidget {
  const _GhostImagePicker({this.onCameraTap, this.onGalleryTap});

  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 130,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColorsJ.main2,
            border: Border.all(color: AppColorsJ.gray3Normal, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '공간을 함께 저장해보세요',
                textAlign: TextAlign.center,
                style: AppTextStyles.textR,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GhostIconBtn(
                    assetPath: 'assets/fonts/icons/mdi_camera.svg',
                    onTap: onCameraTap,
                  ),
                  const SizedBox(width: 6),
                  _GhostIconBtn(
                    assetPath: 'assets/fonts/icons/gallery.svg',
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
  const _GhostIconBtn({
    required this.assetPath,
    this.onTap,
    this.size = 24,
    this.hitSize = 44,
    this.semanticLabel,
  });

  final String assetPath;
  final VoidCallback? onTap;
  final double size;
  final double hitSize;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: hitSize,
        child: Center(
          child: SvgPicture.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            semanticsLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}

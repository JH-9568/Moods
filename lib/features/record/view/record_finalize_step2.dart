import 'dart:io'; // 👈 [추가] File 클래스 사용을 위해 import
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // 👈 [추가] image_picker 패키지 import

import 'package:moods/features/record/controller/record_controller.dart';
import 'package:moods/features/record/view/record_card_preview.dart';

/// =======================
/// Step2 전용 토큰 (Step1과 동일값)
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
  final _spaceCtrl = TextEditingController();

  final Set<String> _selectedEmotions = {};
  final Set<String> _selectedPlaceTags = {};
  bool _submitting = false;

  // 👈 [추가] image_picker 관련 상태 변수
  XFile? _image; // 선택된 이미지를 저장할 변수
  final ImagePicker picker = ImagePicker(); // ImagePicker 인스턴스 생성

  // 👈 [추가] 이미지를 가져오는 함수
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
        });
      }
    } catch (e) {
      // 권한 거부 등의 예외 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지를 가져오는데 실패했습니다: $e')),
        );
      }
    }
  }

  // 👈 [추가] 선택된 이미지를 보여주는 위젯을 만드는 함수
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
              onTap: () {
                setState(() {
                  _image = null; // 이미지 선택 취소
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
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
    final st = ref.watch(recordControllerProvider);

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
                      on
                          ? _selectedEmotions.remove(e)
                          : _selectedEmotions.add(e);
                    });
                  },
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: C.primarySoft,
                  side: const BorderSide(color: C.chipStroke),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: const StadiumBorder(),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 👇 [변경] 이미지 피커 로직 변경
            // 이미지가 선택되었으면 미리보기를, 아니면 선택 버튼들을 보여줌
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: C.chipStroke),
                    ),
                  ),
                  onPressed: () {
                    // TODO: 지도에서 선택
                  },
                  child: const Text('지도에서 선택',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InputBox.text(controller: _spaceCtrl, hint: '직접 입력'),

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
                      on
                          ? _selectedPlaceTags.remove(t)
                          : _selectedPlaceTags.add(t);
                    });
                  },
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: C.primarySoft,
                  side: const BorderSide(color: C.chipStroke),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                backgroundColor: _submitting
                    ? C.primaryDeep.withOpacity(.6)
                    : C.primaryDeep,
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
                        // 1) finalize 메타 저장
                        ref
                            .read(recordControllerProvider.notifier)
                            .applyFinalizeMeta(
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
                          try {
                            return DateTime.parse('$v').toLocal();
                          } catch (_) {
                            return null;
                          }
                        }

                        final endedAt = _iso(data['end_time']) ?? DateTime.now();
                        final startedAt = _iso(data['start_time']) ??
                            endedAt.subtract(Duration(
                                milliseconds: (durSec * 1000).round()));

                        final goalsDone = (data['goals'] is List
                                ? data['goals'] as List
                                : const [])
                            .whereType<Map>()
                            .where((g) => g['done'] == true)
                            .map((g) => (g['text'] ?? '').toString())
                            .where((s) => s.isNotEmpty)
                            .toList();

                        List<String> _toStrList(v) {
                          if (v is List)
                            return v.map((e) => e.toString()).toList();
                          if (v is String && v.isNotEmpty) return [v];
                          return const <String>[];
                        }

                        final moods = _toStrList(data['mood_id']);
                        final emotionTags =
                            _toStrList(data['emotion_tag_ids']);
                        final spaceId = (data['space_id']?.toString() ?? '');

                        final focus = Duration(
                            milliseconds: max(0, (durSec * 1000).round()));

                        if (!mounted) return;

                        final st2 = ref.read(recordControllerProvider);
                        final bgProvider = (st2.wallpaperUrl.trim().isNotEmpty)
                            ? NetworkImage(st2.wallpaperUrl)
                            : null;

                        // TODO: 선택된 이미지가 있다면 FileImage로 bgProvider를 설정하는 로직 추가
                        // final ImageProvider? finalBgProvider = _image != null
                        //     ? FileImage(File(_image!.path))
                        //     : bgProvider;

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
                          placeName: spaceId.isNotEmpty ? spaceId : '미정',
                          placeType: '공간',
                          placeMood: emotionTags.isNotEmpty
                              ? emotionTags.join(', ')
                              : '무드 미정',
                          tags: _selectedPlaceTags.toList(),
                          background: bgProvider, // finalBgProvider 로 교체 가능
                        );

                        if (mounted) {
                          context.go('/record/preview', extra: dataForPreview);
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

/// =======================
/// 로컬 파츠 (라벨/인풋/고스트피커)
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

  const _InputBox.text({
    required this.controller,
    required this.hint,
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
                    color: C.textMain,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
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
  const _GhostIconBtn(
      {required this.icon, required this.label, this.onTap});

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
              border: Border.all(color: C.chipStroke)
            ),
            child: Icon(icon, size: 28, color: C.primaryDeep),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: C.textSub, fontWeight: FontWeight.w500),)
        ],
      ),
    );
  }
}
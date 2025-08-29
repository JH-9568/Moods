// lib/features/record/view/record_timer_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/providers.dart';
import 'package:moods/features/record/controller/record_controller.dart';
import 'fullscreen_timer.dart';

const double _kFont16 = 16;
const double _kLH160  = 1.6;

const _kTextMain = Color(0xFF1B1C20);
const _kTextSub  = Color(0xFF9094A9);

const _kChipFillSelected = Color(0xFFA7B3F1);
const _kChipStroke       = Color(0xFFE8EBF8);

class RecordTimerScreen extends ConsumerStatefulWidget {
  final StartArgs startArgs;
  const RecordTimerScreen({super.key, required this.startArgs});

  @override
  ConsumerState<RecordTimerScreen> createState() => _RecordTimerScreenState();
}

class _RecordTimerScreenState extends ConsumerState<RecordTimerScreen> {
  late final DraggableScrollableController _dragCtrl;
  final List<TextEditingController> _draftCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  String _lastWallUrl = '';
  bool? _wallIsDark;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _dragCtrl = DraggableScrollableController();
  }

  void _startOnceIfTokenReady() {
    if (_started) return;
    final token = ref.read(authTokenProvider);
    if (token != null && token.isNotEmpty) {
      _started = true;
      ref.read(recordControllerProvider.notifier)
         .startWithArgs(widget.startArgs, context: context);
    }
  }

  @override
  void dispose() {
    _dragCtrl.dispose();
    for (final c in _draftCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _onClose() async {
    final st = ref.read(recordControllerProvider);
    if (st.selectedMoods.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => const _Alert(
          title: '잠시만요!',
          message: '공간 무드를 선택해주세요',
          okText: '확인',
        ),
      );
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => const _Confirm(
        title: '공부를 끝내시겠어요?',
        okText: '네\n기록을 저장할래요',
        cancelText: '아니요\n이어서 할게요',
      ),
    );
    if (yes == true) {
      final ctrl = ref.read(recordControllerProvider.notifier);
      await ctrl.finish();
      await ctrl.exportToRecord();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<bool?> _calcIsDark(String url) async {
    try {
      final data = await NetworkAssetBundle(Uri.parse(url)).load('');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec =
          await ui.instantiateImageCodec(bytes, targetWidth: 1, targetHeight: 1);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image img = fi.image;
      final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bd == null || bd.lengthInBytes < 3) return null;
      final r = bd.getUint8(0), g = bd.getUint8(1), b = bd.getUint8(2);
      final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
      return luminance < 0.55;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureWallBrightness(String wallUrl) async {
    if (wallUrl.isEmpty) return;
    if (_lastWallUrl == wallUrl && _wallIsDark != null) return;
    _lastWallUrl = wallUrl;
    final d = await _calcIsDark(wallUrl);
    if (mounted) setState(() => _wallIsDark = d);
  }

  @override
  Widget build(BuildContext context) {
    // 토큰 준비되면 한 번만 시작
    ref.listen<String?>(authTokenProvider, (prev, next) {
      if (!_started && (next?.isNotEmpty ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startOnceIfTokenReady());
      }
    });
    final tokenNow = ref.watch(authTokenProvider);
    if (!_started && (tokenNow?.isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startOnceIfTokenReady());
    }

    final st = ref.watch(recordControllerProvider);
    final ctrl = ref.read(recordControllerProvider.notifier);

    final hasImage = st.wallpaperUrl.isNotEmpty;
    if (hasImage) {
      _ensureWallBrightness(st.wallpaperUrl);
    } else {
      _wallIsDark = null;
    }

    const cardColor = Color(0xFFC8CBF3);
    final Color timeColor = hasImage
        ? (_wallIsDark == null
            ? Colors.white
            : (_wallIsDark! ? Colors.white : Colors.black))
        : Colors.black;

    const BorderRadius cardRadius = BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft: Radius.circular(20),
      bottomRight: Radius.circular(20),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFF),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                // ---- 타이머 카드 ----
                GestureDetector(
                  onVerticalDragEnd: (_) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => const FullscreenTimer(),
                        transitionsBuilder: (_, a, __, child) =>
                            FadeTransition(opacity: a, child: child),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 260,
                    decoration: BoxDecoration(
                      color: hasImage ? null : cardColor,
                      borderRadius: cardRadius,
                      image: hasImage
                          ? DecorationImage(
                              image: NetworkImage(st.wallpaperUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          offset: Offset(0, 6),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          _fmt(st.elapsed),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            fontSize: 50,
                            height: 1.30,
                            letterSpacing: -0.1,
                            color: timeColor,
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          child: Row(
                            children: [
                              _RoundCircleButton(
                                size: 54,
                                iconSize: 22,
                                icon: Icons.close,
                                bg: const Color(0xFFFFFFFF),
                                iconColor: const Color(0xFF4558C1),
                                onTap: _onClose,
                              ),
                              const SizedBox(width: 10),
                              _RoundCircleButton(
                                size: 54,
                                iconSize: 22,
                                icon: st.isRunning
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                bg: const Color(0xFF4558C1),
                                iconColor: const Color(0xFFFFFFFF),
                                onTap: () => st.isRunning
                                    ? ctrl.pause(context: context)
                                    : ctrl.resume(context: context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---- 본문 ----
                Expanded(
                  child: DraggableScrollableSheet(
                    controller: _dragCtrl,
                    initialChildSize: 0.88,
                    minChildSize: 0.60,
                    maxChildSize: 1.00,
                    builder: (_, scroll) => Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFF),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: ListView(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
                        children: [
                          // ---- 공간 무드 ----
                          const Text(
                            '공간 무드',
                            style: TextStyle(
                              fontSize: _kFont16,
                              height: _kLH160,
                              fontWeight: FontWeight.w700,
                              color: _kTextMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '공부하는 공간이 가지고 있는 분위기와 느낌을 선택해주세요.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.6,
                              color: _kTextSub,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _moodTags.map((m) {
                              final on = st.selectedMoods.contains(m);
                              return FilterChip(
                                label: Text(
                                  m,
                                  style: TextStyle(
                                    fontSize: _kFont16,
                                    height: _kLH160,
                                    fontWeight: FontWeight.w500,
                                    // 🔴 요구사항: 미선택 -> 검정, 선택 -> 흰색
                                    color: on ? Colors.white : _kTextMain,
                                  ),
                                ),
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: on ? _kChipFillSelected : _kChipStroke,
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                selectedColor: _kChipFillSelected,
                                showCheckmark: false,
                                selected: on,
                                onSelected: (_) => ref
                                    .read(recordControllerProvider.notifier)
                                    .toggleMood(m),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // ---- 오늘 목표 ----
                          const Text(
                            '오늘 목표',
                            style: TextStyle(
                              fontSize: _kFont16,
                              height: _kLH160,
                              fontWeight: FontWeight.w700,
                              color: _kTextMain,
                            ),
                          ),
                          const SizedBox(height: 12),

                          ...st.goals.asMap().entries.map((e) {
                            final i = e.key;
                            final g = e.value;
                            return _GoalRow(
                              text: g.text,
                              done: g.done,
                              onToggle: (v) => ref
                                  .read(recordControllerProvider.notifier)
                                  .toggleGoal(i, v, context: context),
                            );
                          }),

                          ..._draftCtrls.asMap().entries.map((e) {
                            final c = e.value;
                            return _GoalInputRow(
                              controller: c,
                              onSubmitted: (text) async {
                                final t = text.trim();
                                if (t.isEmpty) return;
                                await ref
                                    .read(recordControllerProvider.notifier)
                                    .addGoal(t, context: context);
                                c.clear();
                              },
                            );
                          }),
                          const SizedBox(height: 8),

                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setState(() {
                                  _draftCtrls.add(TextEditingController());
                                });
                              },
                              child: Container(
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF1FA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.add,
                                    size: 26, color: Color(0xFF6B6BE5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- 하단 뒤로가기 ----
          Positioned(
            left: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 24),
                color: Colors.black87,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 라벨 목록 (아늑한 ↔ 조용한 나란히 표시되도록 마지막에 배치)
const List<String> _moodTags = [
  '트렌디한', '감성적인', '개방적인', '자연친화적인',
  '컨셉있는', '활기찬', '아늑한', '조용한',
];

// ---- 목표 행 ----
class _GoalRow extends StatelessWidget {
  final String text;
  final bool done;
  final Future<void> Function(bool) onToggle;

  const _GoalRow({
    required this.text,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bg      = done ? const Color(0xFFA7B3F1) : Colors.white;
    final checkBg = done ? const Color(0xFF6B6BE5) : const Color(0xFFE8ECF6);
    final textCol = done ? Colors.white : _kTextMain;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onToggle(!done),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // 체크(조금 더 굵어보이도록 done_rounded + size up)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: checkBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.done_rounded,
                    size: 20,
                    color: done ? Colors.white : const Color(0xFFB7BED6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 52,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: _kFont16,
                        height: _kLH160,
                        fontWeight: FontWeight.w500,
                        color: textCol,
                        decoration: TextDecoration.none,
                      ),
                    ),
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

// ---- 목표 입력 ----
class _GoalInputRow extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  const _GoalInputRow({
    required this.controller,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECF6),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.done_rounded, size: 20, color: Color(0xFFB7BED6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 52,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(fontSize: _kFont16, height: _kLH160),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: '목표 입력',
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                onSubmitted: onSubmitted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- 다이얼로그 ----
class _Confirm extends StatelessWidget {
  final String title;
  final String okText;
  final String cancelText;
  const _Confirm(
      {required this.title, required this.okText, required this.cancelText});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText, textAlign: TextAlign.center)),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(okText, textAlign: TextAlign.center)),
      ],
    );
  }
}

class _Alert extends StatelessWidget {
  final String title;
  final String message;
  final String okText;
  const _Alert(
      {required this.title, required this.message, required this.okText});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: Text(okText))
      ],
    );
  }
}

// ---- 공용 원형 버튼 ----
class _RoundCircleButton extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _RoundCircleButton({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
    this.size = 54,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

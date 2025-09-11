// lib/features/record/view/record_timer_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'record_finalize_step1.dart';
import 'package:moods/features/record/controller/record_controller.dart';
import 'fullscreen_timer.dart';
import 'package:moods/common/widgets/back_button.dart';
import 'package:moods/features/record/widget/widget.dart';

const double _kFont16 = 16;
const double _kLH160 = 1.6;

const _kTextMain = Color(0xFF1B1C20);
const _kTextSub = Color(0xFF9094A9);

const _kChipFillSelected = Color(0xFFA7B3F1);
const _kChipStroke = Color(0xFFE8EBF8);

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

  bool _started = false; // 한 번만 스타트
  bool _closing = false; // 닫기 중복 방지

  @override
  void initState() {
    super.initState();
    _dragCtrl = DraggableScrollableController();

    // ⚠️ 프레임 이후에 내비/스낵바 사용
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _started) return;
      _started = true;

      try {
        await ref
            .read(recordControllerProvider.notifier)
            .startWithArgs(widget.startArgs, context: context);
      } catch (e) {
        if (!mounted) return;

        final messenger = ScaffoldMessenger.maybeOf(context);
        final router = GoRouter.of(context);

        if (e.toString().contains('unexported_session_exists')) {
          // 미완료 세션 → 마무리 플로우로
          messenger?.showSnackBar(
            const SnackBar(
                content: Text('마무리하지 않은 기록이 있습니다. 먼저 기록을 완료해주세요.')),
          );
          router.push('/record/finalize_step1');
        } else {
          messenger?.showSnackBar(
            const SnackBar(content: Text('오류가 발생했습니다!')),
          );
          if (router.canPop()) {
            router.pop();
          } else {
            router.go('/home');
          }
        }
      }
    });
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
    if (_closing) return;
    _closing = true;
    try {
      final st = ref.read(recordControllerProvider);

      // 공간 무드 미선택 guard
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

      // 종료 확인
      final yes = await showDialog<bool>(
        context: context,
        builder: (_) => const _Confirm(
          title: '공부를 끝내시겠어요?',
          okText: '네\n기록을 저장할래요',
          cancelText: '아니요\n이어서 할게요',
        ),
      );
      if (yes != true) return;

      // 1) 세션 종료 시도 (이미 종료된 경우는 무시)
      try {
        await ref.read(recordControllerProvider.notifier).finish();
      } catch (e) {
        final msg = e.toString();
        if (!(msg.contains('이미 세션이 종료') ||
            msg.toLowerCase().contains('already'))) {
          debugPrint('finish() error ignored: $e');
        }
      }

      // 2) 기록하기 풀스크린 플로우
      if (!mounted) return;
      await showRecordFinalizeFlow(context);
    } finally {
      _closing = false;
    }
  }

  Future<bool?> _calcIsDark(String url) async {
    try {
      final data = await NetworkAssetBundle(Uri.parse(url)).load('');
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes,
          targetWidth: 1, targetHeight: 1);
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
    final st = ref.watch(recordControllerProvider);
    final ctrl = ref.read(recordControllerProvider.notifier);

    final hasImage = st.wallpaperUrl.isNotEmpty;
    if (hasImage) {
      _ensureWallBrightness(st.wallpaperUrl);
    } else {
      _wallIsDark = null;
    }

    // 시안 색상
    const cardColor = Color(0xFFA7B3F1);

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

                // ---- 본문 (시안처럼 타이머에서 약 80px 아래에서 시작) ----
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      const double kGapFromTimer = 30.0;
                      final double h = constraints.maxHeight;
                      double initial = (h - kGapFromTimer) / h;
                      initial = initial.clamp(0.60, 1.00);

                      return DraggableScrollableSheet(
                        controller: _dragCtrl,
                        initialChildSize: initial,
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
                            padding:
                                const EdgeInsets.fromLTRB(24, 20, 24, 120),
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

                              // Step1과 동일한 3/3/2 칩 그리드
                              MoodChipsFixedGrid(
                                selected: st.selectedMoods,
                                onTap: (m) => ctrl.toggleMood(m),
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

                              // Step1과 동일한 목표 Pill
                              ...st.goals.asMap().entries.map((e) {
                                final i = e.key;
                                final g = e.value;
                                final disabled = g.text.trim().isEmpty;
                                return GoalPillRow(
                                  text: g.text.isEmpty ? '목표' : g.text,
                                  done: g.done,
                                  disabled: disabled,
                                  onToggle: (v) => ref
                                      .read(recordControllerProvider.notifier)
                                      .toggleGoal(i, v, context: context),
                                );
                              }),

                              // 입력 행
                              ..._draftCtrls.asMap().entries.map((e) {
                                final c = e.value;
                                return _GoalInputRow(
                                  controller: c,
                                  onSubmitted: (text) async {
                                    final t = text.trim();
                                    if (t.isEmpty) return;
                                    await ref
                                        .read(recordControllerProvider
                                            .notifier)
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
                                      _draftCtrls
                                          .add(TextEditingController());
                                    });
                                  },
                                  child: Container(
                                    height: 36,
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ---- 하단 뒤로가기 ----
          Positioned(
            left: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(left:12, bottom: 0),
              child: GlobalBackButton(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// 라벨 목록 (아늑한 ↔ 조용한 나란히)
const List<String> _moodTags = [
  '트렌디한',
  '감성적인',
  '개방적인',
  '자연친화적인',
  '컨셉있는',
  '활기찬',
  '아늑한',
  '조용한',
];

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
          ToggleSvg(
            active: false,
            disabled: true,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 30,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: controller,
                style:
                    const TextStyle(fontSize: _kFont16, height: _kLH160),
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
        FilledButton(
            onPressed: () => Navigator.pop(context), child: Text(okText))
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

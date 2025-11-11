// lib/features/record/view/record_timer_screen.dart
// RecordTimerScreen — 리팩토링(정리 버전)
// - 기능/디자인/문자열/스타일 변경 없음
// - 섹션 구분 + 중복 라우팅 메서드 분리만 수행

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

// 공통 스타일/색
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/common/constants/colors_j.dart';

// 1) Constants
const double _kFont16 = 16;
const double _kLH160 = 1.6;

// 라벨 목록 (아늑한 ↔ 조용한 나란히) — 사용처 유지
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

// 2) Screen
class RecordTimerScreen extends ConsumerStatefulWidget {
  final StartArgs startArgs;
  const RecordTimerScreen({super.key, required this.startArgs});

  @override
  ConsumerState<RecordTimerScreen> createState() => _RecordTimerScreenState();
}

class _RecordTimerScreenState extends ConsumerState<RecordTimerScreen> {
  // State fields
  late final DraggableScrollableController _dragCtrl;
  final List<TextEditingController> _draftCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  String _lastWallUrl = '';
  bool? _wallIsDark;

  bool _started = false; // 한 번만 스타트
  bool _closing = false; // 닫기 중복 방지

  // Lifecycle
  @override
  void initState() {
    super.initState();
    _dragCtrl = DraggableScrollableController();

    // 프레임 이후 비동기 시작(스낵바/라우팅 사용)
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
          messenger?.showSnackBar(
            const SnackBar(
              content: Text('마무리하지 않은 기록이 있습니다. 먼저 기록을 완료해주세요.'),
            ),
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

  // Helpers (format/brightness/routing)
  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
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

  void _openFullscreenTimer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const FullscreenTimer(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  // Close flow
  Future<void> _onClose() async {
    if (_closing) return;
    _closing = true;
    try {
      final st = ref.read(recordControllerProvider);

      // 공간 무드 미선택 guard
      if (st.selectedMoods.isEmpty) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.45),
          builder: (_) => const _Alert(
            title: '잠시만요!',
            message: '공간 무드를 선택해주세요',
            okText: '확인',
          ),
        );
        return;
      }

      // 종료 확인 — 커스텀 다이얼로그(시안값)
      final yes = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.45),
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

  // Build
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
    const cardColor = AppColorsJ.main3;

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
      backgroundColor: AppColorsJ.main1,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                // 타이머 카드
                GestureDetector(
                  onVerticalDragEnd: (_) => _openFullscreenTimer(),
                  onTap: _openFullscreenTimer,
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
                          style: AppTextStyles.time.copyWith(color: timeColor),
                        ),
                        Positioned(
                          bottom: 20,
                          child: Row(
                            children: [
                              _RoundCircleButton(
                                size: 54,
                                iconSize: 22,
                                icon: Icons.close,
                                bg: AppColorsJ.white,
                                iconColor: AppColorsJ.main5,
                                onTap: _onClose,
                              ),
                              const SizedBox(width: 10),
                              _RoundCircleButton(
                                size: 54,
                                iconSize: 22,
                                icon:
                                    st.isRunning ? Icons.pause : Icons.play_arrow,
                                bg: AppColorsJ.main4,
                                iconColor: AppColorsJ.white,
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

                // 본문
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
                            color: AppColorsJ.main1,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: ListView(
                            controller: scroll,
                            padding:
                                const EdgeInsets.fromLTRB(24, 20, 24, 120),
                            children: [
                              // 공간 무드
                              const Text(
                                '공간 무드',
                                style: AppTextStyles.textSbEmphasis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '공부하는 공간이 가지고 있는 분위기와 느낌을 선택해주세요.',
                                style: AppTextStyles.small,
                              ),
                              const SizedBox(height: 16),

                              // Step1과 동일한 3/3/2 칩 그리드
                              MoodChipsFixedGrid(
                                selected: st.selectedMoods,
                                onTap: (m) => ctrl.toggleMood(m),
                              ),

                              const SizedBox(height: 24),

                              // 오늘 목표
                              const Text(
                                '오늘 목표',
                                style: AppTextStyles.textSbEmphasis,
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
                                      _draftCtrls
                                          .add(TextEditingController());
                                    });
                                  },
                                  child: Container(
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColorsJ.main2,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 26,
                                      color: AppColorsJ.main5,
                                    ),
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

          // 하단 뒤로가기
          Positioned(
            left: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(left: 12, bottom: 0),
              child: GlobalBackButton(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// 3) Subwidgets

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
          // placeholder 줄은 토글 비활성(디자인 고정)
          const ToggleSvg(active: false, disabled: true, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 30,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),

              // 테두리/라운드, 위 항목과 동일
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  side: BorderSide(
                    color: AppColorsJ.gray3Normal, // 기본 연회색 테두리
                    width: 1,
                  ),
                ),
              ),

              child: TextField(
                controller: controller,

                style: AppTextStyles.textR,

                textInputAction: TextInputAction.done,
                textAlignVertical: TextAlignVertical.center,

                decoration: InputDecoration(
                  hintText: '목표 입력',
                  hintStyle: AppTextStyles.textR.copyWith(color: AppColorsJ.gray5),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
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

/// 시안형 커스텀 Confirm Dialog
class _Confirm extends StatelessWidget {
  final String title;
  final String okText;
  final String cancelText;
  const _Confirm({
    required this.title,
    required this.okText,
    required this.cancelText,
  });

  static const _bg    = AppColorsJ.gray2;
  static const _yesBg = AppColorsJ.main3;
  static const _noBg  = AppColorsJ.gray4;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _bg,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이틀 — AppTextStyles.subtitle(20px)
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                // 왼쪽: 네
                Expanded(
                  child: _BigActionButton(
                    bg: _yesBg,
                    fg: Colors.white,
                    top: '네',
                    bottom: '기록을 저장할게요',
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                // 오른쪽: 아니요
                Expanded(
                  child: _BigActionButton(
                    bg: _noBg,
                    fg: Colors.white,
                    top: '아니요',
                    bottom: '이어서 할게요',
                    onTap: () => Navigator.pop(context, false),
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

class _BigActionButton extends StatelessWidget {
  final Color bg, fg;
  final String top, bottom;
  final VoidCallback onTap;
  const _BigActionButton({
    required this.bg,
    required this.fg,
    required this.top,
    required this.bottom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 위 줄: bodyBold(16)
            Text(
              top,
              style: AppTextStyles.bodyBold.copyWith(color: fg),
            ),
            const SizedBox(height: 2),
            // 아래 줄: small(12)
            Text(
              bottom,
              style: AppTextStyles.small.copyWith(color: fg.withOpacity(0.98)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alert (잠시만요! 공간 무드 선택)
class _Alert extends StatelessWidget {
  final String title;
  final String message;
  final String okText;
  const _Alert({
    required this.title,
    required this.message,
    required this.okText,
  });

  static const _bg    = AppColorsJ.gray2;
  static const _yesBg = AppColorsJ.main3; // 확인 버튼 = 네 버튼색

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _bg,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(color: AppColorsJ.black), // 20px
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: AppColorsJ.gray6), // 14px 회색
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _yesBg,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  okText,
                  style: AppTextStyles.bodyBold.copyWith(color: AppColorsJ.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 공용 원형 버튼
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

// lib/features/record/view/fullscreen_timer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/common/constants/colors_j.dart';
import 'package:moods/features/record/view/record_finalize_step1.dart';
import 'package:moods/features/record/controller/record_controller.dart';

class FullscreenTimer extends ConsumerWidget {
  const FullscreenTimer({super.key});

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _finishFlow(BuildContext context, WidgetRef ref) async { // record_timer_screen의 _onClose 로직과 통합
    final st = ref.read(recordControllerProvider);
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

    if (yes == true) {
      final ctrl = ref.read(recordControllerProvider.notifier);
      try {
        await ctrl.finish();
      } catch (e) {
        final msg = e.toString();
        if (!(msg.contains('이미 세션이 종료') || msg.toLowerCase().contains('already'))) {
          debugPrint('finish() error ignored: $e');
        }
      }
      if (!context.mounted) return;
      await showRecordFinalizeFlow(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(recordControllerProvider);
    final ctrl = ref.read(recordControllerProvider.notifier);
    final hasImage = st.wallpaperUrl.isNotEmpty;

    void closeOnly() => Navigator.of(context).pop();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // 위/아래 스와이프로 풀스크린만 닫기
        onVerticalDragEnd: (details) {
          final v = details.velocity.pixelsPerSecond.dy;
          if (v.abs() > 300) closeOnly();
        },
        child: Stack(
          children: [
            if (hasImage)
              Positioned.fill(
                child: Image.network(st.wallpaperUrl, fit: BoxFit.cover),
              ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),
            // 상단 좌측 뒤로가기(풀스크린만 닫기)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 22),
                  onPressed: closeOnly,
                ),
              ),
            ),
            // 중앙 타이머
            Center(
              child: Text(
                _fmt(st.elapsed),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
            // 하단 버튼
            SafeArea(
              minimum: const EdgeInsets.only(bottom: 24),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RoundCircleButton( // record_timer_screen과 동일한 디자인/기능
                      icon: Icons.close,
                      bg: AppColorsJ.white,
                      iconColor: AppColorsJ.main5,
                      onTap: () => _finishFlow(context, ref),
                      size: 54,
                      iconSize: 22,
                    ),
                    const SizedBox(width: 16),
                    _RoundCircleButton( // record_timer_screen과 동일한 디자인/기능
                      icon: st.isRunning ? Icons.pause : Icons.play_arrow,
                      bg: AppColorsJ.main4,
                      iconColor: AppColorsJ.white,
                      onTap: () async {
                        if (st.isRunning) {
                          await ctrl.pause(context: context);
                        } else {
                          await ctrl.resume(context: context);
                        }
                      },
                      size: 54,
                      iconSize: 22,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================
// 공용 위젯들 (이 파일 내에서만 사용)
// =====================
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

class _Confirm extends StatelessWidget {
  final String title;
  final String okText;
  final String cancelText;
  const _Confirm(
      {required this.title, required this.okText, required this.cancelText});
  @override
  Widget build(BuildContext context) {
    // record_timer_screen의 _Confirm 위젯을 가져와서 사용
    return Dialog(
      backgroundColor: AppColorsJ.gray2,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColorsJ.main3, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 8), minimumSize: const Size(0, 58)),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(okText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.3)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColorsJ.gray4, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 8), minimumSize: const Size(0, 58)),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(cancelText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.3)),
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

class _Alert extends StatelessWidget {
  final String title;
  final String message;
  final String okText;
  const _Alert({required this.title, required this.message, required this.okText});
  @override
  Widget build(BuildContext context) {
    // record_timer_screen의 _Alert 위젯을 가져와서 사용
    return Dialog(
      backgroundColor: AppColorsJ.gray2,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColorsJ.gray6)),
            const SizedBox(height: 18),
            SizedBox(height: 50, width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColorsJ.main3, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: () => Navigator.pop(context), child: Text(okText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
          ],
        ),
      ),
    );
  }
}
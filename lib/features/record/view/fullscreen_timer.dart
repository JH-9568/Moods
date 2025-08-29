// lib/features/record/view/fullscreen_timer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moods/features/record/controller/record_controller.dart';

class FullscreenTimer extends ConsumerWidget {
  const FullscreenTimer({super.key});

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _finishFlow(BuildContext context, WidgetRef ref) async {
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
      await ctrl.exportToRecord(); // Controller가 상태를 알고 있으므로 파라미터 필요 없음

      if (!context.mounted) return;
      // 풀스크린 닫고, 이전 화면(RecordTimerScreen)도 닫기
      Navigator.of(context).pop();
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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
                    _RoundCircleButton(
                      icon: Icons.close,
                      bg: Colors.white,
                      iconColor: const Color(0xFF4558C1),
                      onTap: () => _finishFlow(context, ref),
                      size: 54,
                      iconSize: 22,
                    ),
                    const SizedBox(width: 16),
                    _RoundCircleButton(
                      icon: st.isRunning ? Icons.pause : Icons.play_arrow,
                      bg: const Color(0xFF4558C1),
                      iconColor: Colors.white,
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
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black45)],
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
  const _Alert({required this.title, required this.message, required this.okText});
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
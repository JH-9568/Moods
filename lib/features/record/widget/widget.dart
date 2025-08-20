// 공용 위젯 모음: 타이머 카드, 라운드 버튼, 다이얼로그
import 'package:flutter/material.dart';

class TimerCard extends StatelessWidget {
  final String elapsedText;
  final VoidCallback onClose;
  final VoidCallback onToggleRun;
  final bool isRunning;
  final String wallpaperUrl;
  const TimerCard({
    super.key,
    required this.elapsedText,
    required this.onClose,
    required this.onToggleRun,
    required this.isRunning,
    required this.wallpaperUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bg = wallpaperUrl.isNotEmpty
        ? DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(image: NetworkImage(wallpaperUrl), fit: BoxFit.cover),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const SizedBox(height: 220),
          )
        : Container(height: 220, decoration: BoxDecoration(color: const Color(0xFFD1D1F4), borderRadius: BorderRadius.circular(24)));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          bg,
          const SizedBox(height: 16),
          Text(elapsedText, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _RoundButton(icon: Icons.close, onTap: onClose),
            const SizedBox(width: 16),
            _RoundButton(icon: isRunning ? Icons.pause : Icons.play_arrow, onTap: onToggleRun),
          ]),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String okText;
  final String cancelText;
  const ConfirmDialog({super.key, required this.title, required this.okText, required this.cancelText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelText, textAlign: TextAlign.center)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(okText, textAlign: TextAlign.center)),
      ],
    );
  }
}

class AlertDialogBasic extends StatelessWidget {
  final String title;
  final String message;
  final String okText;
  const AlertDialogBasic({super.key, required this.title, required this.message, required this.okText});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(okText))],
    );
  }
}

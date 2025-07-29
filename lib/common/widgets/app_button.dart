import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool isOutlined;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isOutlined
        ? Colors.transparent
        : isEnabled
            ? AppColors.buttonActive
            : AppColors.buttonInactive;

    final Color borderColor = isOutlined
        ? (isEnabled ? AppColors.buttonActive : AppColors.buttonInactive)
        : Colors.transparent;

    final Color textColor = isOutlined
        ? (isEnabled ? AppColors.buttonActive : AppColors.buttonInactive)
        : AppColors.white;

    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30), // 디자이너 가이드
          border: Border.all(color: borderColor),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ).copyWith(color: textColor),
        ),
      ),
    );
  }
}

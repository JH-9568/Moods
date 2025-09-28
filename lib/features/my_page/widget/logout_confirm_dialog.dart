// lib/features/my_page/setting/logout/logout_confirm_dialog.dart
import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moods/features/auth/controller/auth_controller.dart';

Future<void> showLogoutConfirmDialog(
  BuildContext parentContext,
  WidgetRef ref,
) {
  return showDialog<void>(
    context: parentContext,
    barrierDismissible: true,
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: 329,
        height: 160,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀: '로그아웃'만 두껍게
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 8),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.subtitle.copyWith(color: Colors.black),
                    children: [
                      TextSpan(
                        text: '로그아웃',
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(text: ' 하시겠어요?', style: AppTextStyles.subtitle),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 네
                  _DialogButton(
                    label: '네',
                    width: 142,
                    height: 48,
                    textStyle: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    background: AppColors.sub,
                    foreground: Colors.white,
                    onTap: () async {
                      // 1) 다이얼로그 닫기
                      Navigator.of(dialogCtx).pop(true);
                      // 2) 로그아웃
                      await ref.read(authControllerProvider.notifier).logout();
                      // 3) 라우팅 (부모 context 사용)
                      if (!parentContext.mounted) return;
                      parentContext.go('/start');
                    },
                  ),

                  // 아니요
                  _DialogButton(
                    label: '아니요',
                    width: 142,
                    height: 48,
                    textStyle: AppTextStyles.body.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    background: AppColors.text_color3,
                    foreground: Colors.white,
                    onTap: () => Navigator.of(dialogCtx).pop(false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DialogButton extends StatelessWidget {
  final String label;
  final double width;
  final double height;
  final TextStyle textStyle;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _DialogButton({
    super.key,
    required this.label,
    required this.width,
    required this.height,
    required this.textStyle,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Center(child: Text(label, style: textStyle)),
        ),
      ),
    );
  }
}

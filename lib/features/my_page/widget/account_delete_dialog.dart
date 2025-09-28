import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/my_page/setting/account_delete/account_delete_controller.dart';

Future<void> showAccountDeleteDialog(
  BuildContext parentContext,
  WidgetRef ref,
) {
  return showDialog<void>(
    context: parentContext,
    barrierDismissible: true,
    builder: (dialogCtx) {
      bool isBusy = false;

      return StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            width: 329,
            height: 160,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 타이틀: '탈퇴'만 두껍게
                      Padding(
                        padding: const EdgeInsets.only(left: 10, top: 8),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.subtitle.copyWith(
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: '탈퇴',
                                style: AppTextStyles.subtitle.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: ' 하시겠어요?',
                                style: AppTextStyles.subtitle,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          '탈퇴하시면 회원님의 정보가 모두 사라져요!',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.text_color2,
                          ),
                        ),
                      ),
                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 네 (확인)
                          _DialogButton(
                            enabled: !isBusy,
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
                              if (isBusy) return;
                              setState(() => isBusy = true);

                              try {
                                // 1) 다이얼로그 먼저 닫기(뒤 화면 이탈 방지용)
                                Navigator.of(dialogCtx).pop(true);

                                // 2) 계정 삭제 호출
                                await ref
                                    .read(accountControllerProvider.notifier)
                                    .deleteUser();

                                // 3) 시작 화면으로
                                if (!parentContext.mounted) return;
                                parentContext.go('/start');
                              } catch (e) {
                                // 에러 토스트
                                if (parentContext.mounted) {
                                  ScaffoldMessenger.of(
                                    parentContext,
                                  ).showSnackBar(
                                    SnackBar(content: Text('탈퇴 실패: $e')),
                                  );
                                }
                                // 다이얼로그는 이미 닫혀있음. 필요 시 재표시 로직을 호출부에서 처리.
                              } finally {
                                if (ctx.mounted) setState(() => isBusy = false);
                              }
                            },
                          ),

                          // 아니요 (취소)
                          _DialogButton(
                            enabled: !isBusy,
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

                // 진행 중 오버레이
                if (isBusy)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
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
  final bool enabled;

  const _DialogButton({
    super.key,
    required this.label,
    required this.width,
    required this.height,
    required this.textStyle,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: enabled ? onTap : null,
            child: Center(child: Text(label, style: textStyle)),
          ),
        ),
      ),
    );
  }
}

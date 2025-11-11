import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/my_page/setting/account_delete/account_delete_controller.dart';
import 'package:moods/features/my_page/widget/logout_confirm_dialog.dart';
import 'package:moods/features/my_page/widget/account_delete_dialog.dart';

class SettingSection extends ConsumerWidget {
  final String appVersionText;
  const SettingSection({super.key, this.appVersionText = '1.0v'});

  Future<bool?> _confirm(BuildContext ctx, String msg) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountControllerProvider);

    ref.listen<AccountState>(accountControllerProvider, (prev, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('에러: ${next.error}')));
      } else if (next.lastMessage != null && next.lastMessage!.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.lastMessage!)));
      }
    });

    return Container(
      margin: EdgeInsets.zero,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      // ︎ 가로패딩 제거, 세로패딩만
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전폭 라인
          _line(),
          // 나머지는 개별적으로 좌우 16 패딩
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _TitleRow(),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _tile(
              title: Text(
                '로그아웃',
                style: AppTextStyles.small.copyWith(color: Colors.black),
              ),
              onTap: () {
                // ref를 함께 전달하고 결과를 기다리지 않는다
                showLogoutConfirmDialog(context, ref);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _tile(
              title: Text(
                '탈퇴',
                style: AppTextStyles.small.copyWith(color: Colors.black),
              ),
              onTap: () {
                showAccountDeleteDialog(context, ref);
              },
              trailing: account.deleting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _tile(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '버전 정보',
                    style: AppTextStyles.small.copyWith(color: Colors.black),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    appVersionText,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.text_color2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow();

  @override
  Widget build(BuildContext context) {
    return Text('설정', style: AppTextStyles.subtitle);
  }
}

// 전폭 라인 (컨테이너 가로패딩이 없으니 카드 폭 전체를 사용)
Widget _line() => Container(
  height: 3,
  decoration: BoxDecoration(
    color: AppColors.border,
    borderRadius: BorderRadius.circular(1),
  ),
);

// 그대로 사용
Widget _tile({required Widget title, VoidCallback? onTap, Widget? trailing}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(child: title),
          if (trailing != null) trailing,
        ],
      ),
    ),
  );
}

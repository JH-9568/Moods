// lib/features/my_page/setting/setting_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/my_page/setting/account_delete/account_delete_controller.dart';

class SettingSection extends ConsumerWidget {
  final String appVersionText;
  const SettingSection({super.key, this.appVersionText = '1.0v'});

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
      width: 361,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(),
          Text('설정', style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          _tile(
            title: '로그아웃',
            onTap: account.deleting
                ? null
                : () async {
                    try {
                      await Supabase.instance.client.auth.signOut();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('로그아웃 되었습니다.')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('로그아웃 실패: $e')));
                    }
                  },
          ),
          _tile(
            title: '탈퇴',
            onTap: account.deleting
                ? null
                : () async {
                    final ok = await _confirm(
                      context,
                      '정말 탈퇴하시겠어요?\n모든 데이터가 삭제됩니다.',
                    );
                    if (ok != true) return;
                    await ref
                        .read(accountControllerProvider.notifier)
                        .deleteUser();
                  },
            trailing: account.deleting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          _tile(
            title: '버전 정보',
            trailing: Text(
              appVersionText,
              style: AppTextStyles.small.copyWith(color: AppColors.text_color2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line() => Container(
    height: 1,
    color: Colors.black.withOpacity(0.06),
    margin: const EdgeInsets.only(bottom: 6),
  );

  Widget _tile({required String title, VoidCallback? onTap, Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppTextStyles.bodyBold)),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

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
}

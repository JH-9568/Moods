// lib/features/my_page/user_profile/user_profile_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';
import 'package:moods/features/my_page/user_profile/user_profile_controller.dart';

/// 마이페이지 상단 프로필 영역 (272x69)
class UserProfileWidget extends ConsumerWidget {
  const UserProfileWidget({super.key, this.onEdit});

  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userProfileControllerProvider);
    final notifier = ref.read(userProfileControllerProvider.notifier);

    if (!state.loading && !state.loadedOnce && state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.loadIfNeeded();
      });
    }

    final nickname = state.profile?.nickname?.trim();
    final birthday = state.profile?.birthday?.trim();
    final email = state.profile?.email?.trim();
    final genderRaw = state.profile?.gender?.trim().toLowerCase();
    final genderKo = (genderRaw == 'm')
        ? '남'
        : (genderRaw == 'f')
        ? '여'
        : (genderRaw == null || genderRaw.isEmpty ? '' : genderRaw);

    final nickText = state.loading && !state.loadedOnce
        ? '…'
        : (nickname == null || nickname.isEmpty ? '-' : nickname);
    final birthGenderText = state.loading && !state.loadedOnce
        ? '…'
        : [
            if (birthday != null && birthday.isNotEmpty) birthday,
            if (genderKo.isNotEmpty) genderKo,
          ].join(' ');
    final emailText = state.loading && !state.loadedOnce
        ? '…'
        : (email == null || email.isEmpty ? '-' : email);

    return Container(
      width: 272,
      height: 69,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 왼쪽: 닉네임
          Expanded(
            flex: 1,
            child: Text(
              nickText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title.copyWith(color: Colors.black),
            ),
          ),
          const SizedBox(width: 12),
          // 오른쪽: 생일+성별 / 이메일 / 수정하기
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  birthGenderText.isEmpty ? '-' : birthGenderText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  emailText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(color: Colors.black),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: onEdit,
                  child: Text(
                    '수정하기',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.text_color2,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.text_color2,
                    ),
                  ),
                ),
                if (state.error != null && state.error!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

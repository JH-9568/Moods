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

    // 최초 1회 로딩
    if (!state.loading && !state.loadedOnce && state.error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.loadIfNeeded();
      });
    }

    final nickname = state.profile?.nickname.trim();
    final birthday = state.profile?.birthday?.trim();
    final email = state.profile?.email.trim();
    final genderRaw = (state.profile?.gender ?? '').trim().toLowerCase();
    final genderKo = genderRaw == 'male'
        ? '남'
        : genderRaw == 'female'
        ? '여'
        : (genderRaw.isEmpty ? '' : genderRaw);

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
      // 아래 통계와 폭을 맞추기 위해 고정 300 → 꽉 채움
      width: double.infinity,
      height: 69,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.main,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        // 좌/우 1:1 분할 + 자식들을 높이에 맞춰 늘려서 정렬 제어가 쉽도록
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 좌측: 닉네임 - 세로 '정중앙'
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                nickText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title.copyWith(
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ),

          // 가운데 여백 제거(수직 기준선을 아래 통계와 정확히 맞추기 위함)

          // 우측: 생일+성별 / 이메일 / 수정하기 - 좌측정렬 & 위쪽부터 시작
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 내용만큼만 세로 사용 (오버플로우 방지 도움)
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    birthGenderText.isEmpty ? '-' : birthGenderText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 1), // ↓ 오버플로우 2px 방지: 2→1로 줄임
                  Text(
                    emailText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 1), // ↓ 동일
                  InkWell(
                    onTap: onEdit,
                    child: Text(
                      '수정하기',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.text_color3,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.text_color3,
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
          ),
        ],
      ),
    );
  }
}

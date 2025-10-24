// lib/features/my_page/user_profile/user_profile_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final birthday = state.profile?.birthday?.trim(); // 보통 'YYYY-MM-DD'
    final email = state.profile?.email.trim();
    final genderRaw = (state.profile?.gender ?? '').trim().toLowerCase();

    // 표시용(한글) ─ male/m → 남, female/f → 여
    final genderKo = (genderRaw == 'male' || genderRaw == 'm')
        ? '남'
        : (genderRaw == 'female' || genderRaw == 'f')
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
      width: double.infinity,
      height: 69,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.room_color2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 좌측: 닉네임
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

          // 우측: 생일/성별/이메일/수정하기
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    birthGenderText.isEmpty ? '-' : birthGenderText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    emailText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 1),

                  // 🔽🔽🔽 여기 변경: 탭 시 /profile/edit 로 이동 (초깃값 전달)
                  InkWell(
                    onTap:
                        onEdit ??
                        () {
                          // 서버 gender 값이 male/female/m/f 어떤 포맷이든 letter(m/f)로 변환
                          final genderLetter =
                              (genderRaw == 'male' || genderRaw == 'm')
                              ? 'm'
                              : (genderRaw == 'female' || genderRaw == 'f')
                              ? 'f'
                              : '';

                          context.push(
                            '/profile/edit',
                            extra: {
                              'nickname': nickname ?? '',
                              'birthday': birthday ?? '', // 'YYYY-MM-DD'
                              'gender': genderLetter, // 'm' | 'f' | ''
                            },
                          );
                        },
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

                  // 🔼🔼🔼
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

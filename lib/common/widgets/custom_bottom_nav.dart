import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:moods/common/constants/colors.dart';
import 'package:moods/common/constants/text_styles.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    final tabs = [
      {
        'label': '홈',
        'path': '/home',
        'icon': 'assets/fonts/icons/home.svg',
        'selectedIcon': 'assets/fonts/icons/home_selected.svg',
      },
      {
        'label': '공간 추천',
        'path': '/explore',
        'icon': 'assets/fonts/icons/thumb.svg',
        'selectedIcon': 'assets/fonts/icons/thumb_selected.svg',
      },
      {
        'label': '맵',
        'path': '/map',
        'icon': 'assets/fonts/icons/map.svg',
        'selectedIcon': 'assets/fonts/icons/map_selected.svg',
      },
      {
        'label': '마이페이지',
        'path': '/profile',
        'icon': 'assets/fonts/icons/mypage.svg',
        'selectedIcon': 'assets/fonts/icons/mypage_selected.svg',
      },
    ];

    final currentIndex =
        tabs.indexWhere((tab) => location.startsWith(tab['path']!));

return Container(
  height: 87,
  padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 12),
  decoration: BoxDecoration(
    color: const Color(0xFFD0D0FF),
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(tabs.length, (index) {
      final isSelected = index == currentIndex;
      final iconPath = isSelected
          ? tabs[index]['selectedIcon']!
          : tabs[index]['icon']!;
      final textColor = isSelected ? AppColors.dark : AppColors.black;

      return GestureDetector(
        onTap: () {
          context.go(tabs[index]['path']!);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center, // 추가
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 4),
            Text(
              tabs[index]['label']!,
              style: AppTextStyles.small.copyWith(color: textColor),
            ),
          ],
        ),
      );
    }),
  ),
);
  }
}
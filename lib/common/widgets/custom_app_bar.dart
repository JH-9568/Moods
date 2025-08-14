import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      height: statusBarHeight + 70.0, // 전체 높이
      color: AppColors.sub,
      padding: EdgeInsets.only(
        top: statusBarHeight + 12.0, // 상태바 아래 살짝 여백
        left: 20.0,
        right: 20.0,
        bottom: 12.0, // 너무 크지 않게 줄임
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Text(
            'Moods',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: AppColors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Icon(
            Icons.person,
            size: 24,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(98.0); // 디자이너 시안 기준
}

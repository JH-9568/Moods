// lib/common/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  static const double _totalHeight = 98.0; // ✅ 상태바 포함 총 높이 고정

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      height: _totalHeight, // ⬅️ 전체(상태바 포함) 높이
      color: AppColors.sub,
      padding: EdgeInsets.only(
        top: statusBarHeight, // ✅ 상태바만큼 내려서 텍스트가 겹치지 않게
        left: 20.0,
        right: 20.0,
        bottom: 12.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Text(
            'Moods',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: AppColors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Scaffold가 이 값을 높이로 사용합니다.
  // “상태바 포함 총 98”을 보장하려고 preferredSize도 98로 고정합니다.
  @override
  Size get preferredSize => const Size.fromHeight(_totalHeight);
}

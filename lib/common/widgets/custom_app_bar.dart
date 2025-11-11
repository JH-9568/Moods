// lib/common/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import 'package:moods/common/constants/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  // 상태바를 포함한 총 높이를 고정해 디자인 일관성을 유지
  static const double _totalHeight = 98.0;

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      // 전체 영역(상태바 포함) 높이
      height: _totalHeight,
      color: AppColors.sub,
      padding: EdgeInsets.only(
        // 상태바만큼 내려서 텍스트가 겹치지 않게 조정
        top: statusBarHeight,
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
              height: 1.2,
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

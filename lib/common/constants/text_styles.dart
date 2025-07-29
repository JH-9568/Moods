import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const title = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w700, // bold
    fontSize: 26,
    height: 1.4,
    color: AppColors.black,
  );

  static const subtitle = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w500, // medium
    fontSize: 20,
    height: 1.4,
    color: AppColors.black,
  );

  static const bodyBold = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w600, // semibold
    fontSize: 16,
    height: 1.4,
    color: AppColors.black,
  );

  static const body = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400, // regular
    fontSize: 16,
    height: 1.4,
    color: AppColors.black,
  );

  static const caption = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.4,
    color: AppColors.grayText,
  );

  static const small = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.4,
    color: AppColors.grayText,
  );
}

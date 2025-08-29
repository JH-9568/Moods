import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const title = TextStyle( //Title
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w700, // bold
    fontSize: 26,
    height: 1.4,
    color: AppColors.black,
  );

  static const subtitle = TextStyle( //Subtitle
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w500, // medium
    fontSize: 20,
    height: 1.4,
    color: AppColors.black,
  );

  static const bodyBold = TextStyle( //body/text SB 강조
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w600, // semibold
    fontSize: 16,
    height: 1.4,
    color: AppColors.black,
  );

  static const body = TextStyle( //body/text R
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400, // regular
    fontSize: 16,
    height: 1.4,
    color: AppColors.black,
  );

  static const caption = TextStyle( //caption
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.4,
    color: AppColors.grayText,
  );

  static const small = TextStyle( //body/small R12
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.4,
    color: AppColors.grayText,
  );
}

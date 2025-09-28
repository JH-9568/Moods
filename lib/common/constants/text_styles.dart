import 'package:flutter/material.dart';
import 'colors.dart';
import 'colors_j.dart';
class AppTextStyles {
  static const title = TextStyle( //Title
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w700, // bold
    fontSize: 26,
    height: 1.3,
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

  /// Time (Pretendard Medium 50, LH 130%, LS -0.2%)
  static const time = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w500, // Medium
    fontSize: 50,
    height: 1.3,                 // 130%
    letterSpacing: -0.1,         // -0.2% of 50 = -0.1px
    color: AppColors.black,
  );

  /// text SB 강조 (SemiBold 16, LH 160%, LS 2%)
  static const textSbEmphasis = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 16,
    height: 1.6,                 // 160%
    letterSpacing: 0.32,         // 2% of 16 = 0.32px
    color: AppColors.black,
  );

  /// text R (Regular 16, LH 140%, LS 0%)
  static const textR = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400, // Regular
    fontSize: 16,
    height: 1.4,                 // 140%
    letterSpacing: 0.0,
    color: AppColors.black,
  );

  /// small SB강조 (SemiBold 12, LH 140%, LS 0%)
  static const smallSb = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w600, // SemiBold
    fontSize: 12,
    height: 1.4,                 // 140%
    letterSpacing: 0.0,
    color: AppColors.black,
  );
    static const smallR10 = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400, // SemiBold
    fontSize: 10,
    height: 1.4,                 // 140%
    letterSpacing: 0.0,
    color: AppColors.black,
  );

  /// small R12 (Regular 12, LH 140%, LS 0%)
  static const smallR12 = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400, // Regular
    fontSize: 12,
    height: 1.4,                 // 140%
    letterSpacing: 0.0,
    color: AppColorsJ.black,   
  );
}
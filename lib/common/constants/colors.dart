import 'package:flutter/material.dart';

/// 앱 전역에서 사용되는 색상 토큰
class AppColors {
  static const main = Color.fromRGBO(121, 97, 86, 1);
  static const background = Color.fromRGBO(255, 255, 255, 1);
  static const checked = Color.fromRGBO(121, 97, 84, 1);
  static const unchecked = Color.fromRGBO(225, 219, 212, 1);
  static const border = Color.fromRGBO(241, 232, 226, 1);
  static const sub = Color.fromRGBO(157, 137, 123, 1);
  static const text_color1 = Color.fromRGBO(82, 62, 48, 1);
  static const text_color2 = Color.fromRGBO(130, 126, 122, 1);
  static const text_color3 = Color.fromRGBO(195, 188, 181, 1);
  static const room_color1 = Color.fromRGBO(132, 109, 96, 1);
  static const room_color2 = Color.fromRGBO(113, 90, 77, 1);
  // Default
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Gray
  static const Color gray1 = Color.fromARGB(
    255,
    247,
    248,
    249,
  ); // F7F8F9     // light
  static const Color grayNormal = Color(0xFFEDEDED); // normal
  static const Color grayText = Color(0xFFBDBDBD); // text

  // Main
  static const Color main2 = Color.fromARGB(255, 232, 235, 248);
  static const Color main1 = Color(0xFFBDBDF5); // main
  static const Color sub1 = Color(0xFFE6E6FA); // sub
  static const Color back = Color.fromARGB(255, 249, 250, 255); // back
  static const Color middlePoint = Color(0xFF9B9BDE); // middle-point
  static const Color dark = Color(0xFF4A4A8A); // dark

  // Point
  static const Color point = Color(0xFFF4DA74); // point
  static const Color pointLight = Color(0xFFF9E7A5); // point-light

  // State (CTA 등)
  static const Color buttonActive = Color(0xFFBDBDF5); // 활성화
  static const Color buttonInactive = Color(0xFFD9D9E0); // 비활성화

  // Record Screens
  static const Color recordBg = Color(0xFFF3F5FF);
  static const Color recordTimerBg = Color(0xFFF9FAFF);
  static const Color recordPrimaryDeep = Color(0xFF6E6BF0);
  static const Color recordPrimarySoft = Color(0xFFA7B3F1);
  static const Color recordChipStroke = Color(0xFFE5E7F4);
  static const Color recordTextMain = Color(0xFF111318);
  static const Color recordTextSub = Color(0xFF8C90A4);
  static const Color recordTextWeak = Color(0xFFB7BED6);
  static const Color recordDisabledFill = Color(0xFFF0F2F8);
  static const Color recordDisabledText = Color(0xFFB9C0D6);
  static const Color recordBrown = Color(0xFF9D897B);
  static const Color recordDialogBg = Color(0xFFF2F4FF);
  static const Color recordDialogNo = Color(0xFFB5B9C3);

  static const Color kBottomNavBackground = Color(0xFFD1D1F4); // Fill
  static const Color kBottomNavBorder = Color(0xFF000000); // Border
  static const Color kBottomNavShadow = Colors.black12; // Drop shadow 비슷한 거
}

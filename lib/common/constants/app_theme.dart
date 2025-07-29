import 'package:flutter/material.dart';
import 'colors.dart';

final ThemeData appTheme = ThemeData(
  fontFamily: 'Pretendard',
  scaffoldBackgroundColor: AppColors.back,
  primaryColor: AppColors.main,
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700), // 제목
    titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),  // 소제목
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),    // 본문 강조
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),   // 일반 본문
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),    // 캡션
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),   // 작은 글씨
  ),
  useMaterial3: true,
);

         
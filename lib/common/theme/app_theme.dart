import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  fontFamily: 'Pretendard',
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.4),  // 제목
    titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, height: 1.4),   // 소제목
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),     // 본문 강조
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4),    // 일반 본문
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),     // 캡션
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),    // 작은 글씨
  ),
);

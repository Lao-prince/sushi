import 'package:flutter/material.dart';

class AppTextStyles {
  // H1
  static const TextStyle H1 = TextStyle(
    color: Color(0xFFFDFDFD), // Белый цвет
    fontSize: 36,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w300,
    height: 1.0, // Соответствует line-height 36px / 36px
    letterSpacing: 0.72,
    fontFamilyFallback: ['Arial'],
  );

  // H2
  static const TextStyle H2 = TextStyle(
    color: Color(0xFFFDFDFD), // Белый цвет
    fontSize: 28,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w300,
    height: 1.07143, // 30px / 28px
    letterSpacing: 0.0, // Нет указания
    fontFamilyFallback: ['Arial'],
  );

  // H3
  static const TextStyle H3 = TextStyle(
    color: Color(0xFFFDFDFD), // Белый цвет
    fontSize: 24,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w300,
    height: 1.16667, // 28px / 24px
    letterSpacing: 0.48,
    fontFamilyFallback: ['Arial'],
  );

  // Title
  static const TextStyle Title = TextStyle(
    color: Color(0xFFFDFDFD), // Белый цвет
    fontSize: 20,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w300,
    height: 1.2, // 24px / 20px
    letterSpacing: 0.2,
    fontFamilyFallback: ['Arial'],
  );

  // Subtitle
  static const TextStyle Subtitle = TextStyle(
    color: Color(0xFFFDFDFD), // Белый цвет
    fontSize: 18,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w300,
    height: 0.94444, // 17px / 18px
    letterSpacing: 0.54,
    fontFamilyFallback: ['Arial'],
  );

  // Body
  static const TextStyle Body = TextStyle(
    color: Color(0xFFFDFDFD), // Белый цвет
    fontSize: 16,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w300,
    height: 0.9375, // 15px / 16px
    letterSpacing: 0.0, // Нет указания
    fontFamilyFallback: ['Arial'],
  );

  // Caption
  static const TextStyle Caption = TextStyle(
    color: Color(0xFFFDFDFD), // Белый цвет
    fontSize: 14,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w300,
    height: 1.14286, // 16px / 14px
    letterSpacing: 0.0, // Нет указания
    fontFamilyFallback: ['Arial'],
  );
}

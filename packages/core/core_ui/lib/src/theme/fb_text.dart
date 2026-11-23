import 'package:flutter/widgets.dart';

import 'fb_colors.dart';

/// 글자 스타일. 피그마 「글자 역할」(headlineLarge 32 · headlineMedium 24 · titleLarge 22 ·
/// titleMedium 18 · bodyLarge 18 · bodyMedium 16 · labelLarge 16 · labelSmall 13)을 따릅니다.
/// 큰 글씨·어르신 화면 확대는 앱 셸이 MediaQuery 글자 배율로 적용합니다.
abstract final class FbText {
  static const _tabular = [FontFeature.tabularFigures()];

  // headlineMedium 24 · 700 · 32
  static TextStyle greet(FbColors c) =>
      TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -.6, height: 32 / 24, color: c.ink);
  static TextStyle greetSub(FbColors c) => TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.muted);
  // titleMedium 18 · 700 · 28
  static TextStyle cardTitle(FbColors c) =>
      TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -.4, height: 28 / 18, color: c.ink);
  static TextStyle cardDesc(FbColors c) => TextStyle(fontSize: 15, height: 1.55, color: c.ink2);
  static TextStyle more(FbColors c) => TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.muted);
  static TextStyle label(FbColors c) => TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.muted);
  // headlineLarge 32 · 700 · 40 (잔액)
  static TextStyle balance(FbColors c) => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 40 / 32,
    color: c.ink,
    fontFeatures: _tabular,
  );
  static TextStyle bigAmount(FbColors c) =>
      TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -.8, color: c.ink, fontFeatures: _tabular);
  // labelLarge 16 · 600 · 24
  static TextStyle rowTitle(FbColors c) => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5, color: c.ink);
  // labelSmall 13 · 400 · 20
  static TextStyle rowSub(FbColors c) => TextStyle(fontSize: 13, height: 20 / 13, color: c.muted);
  static TextStyle amount(FbColors c) =>
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink, fontFeatures: _tabular);
  static TextStyle note(FbColors c) => TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.muted);
  static TextStyle small(FbColors c) => TextStyle(fontSize: 13, height: 20 / 13, color: c.muted);
  static TextStyle hint(FbColors c) => TextStyle(fontSize: 14, height: 1.55, color: c.muted);
  // bodyMedium 16 · 400 · 24
  static TextStyle body(FbColors c) => TextStyle(fontSize: 16, height: 1.5, color: c.ink2);
  static TextStyle button = const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.4);
  // titleLarge 22 · 700 · 32
  static TextStyle sheetTitle(FbColors c) =>
      TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.6, height: 32 / 22, color: c.ink);
  static TextStyle resultTitle(FbColors c) =>
      TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -.6, color: c.ink, height: 32 / 24);
  static TextStyle tabular(TextStyle s) => s.copyWith(fontFeatures: _tabular);
}

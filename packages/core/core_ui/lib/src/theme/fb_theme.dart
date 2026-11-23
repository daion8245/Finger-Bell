import 'package:flutter/material.dart';

import 'fb_colors.dart';

/// Material 3 테마. 앱에 넣은 Noto Sans KR(가변 글꼴)을 씁니다.
/// FontWeight가 글꼴의 wght 축(100~900)에 그대로 적용됩니다.
/// 모서리·외곽선은 피그마 토큰(작게 8 · 중간 12 · 크게 16 · 아주 크게 28, 외곽선 1, 그림자 없음)을 따릅니다.
abstract final class FbTheme {
  /// core_ui 패키지에 들어 있는 글꼴 이름 (pubspec의 family).
  static const fontFamily = 'packages/core_ui/NotoSansKR';
  static const fontFallback = ['Apple SD Gothic Neo', 'Malgun Gothic', 'sans-serif'];

  static ThemeData build({bool highContrast = false}) {
    final c = highContrast ? FbColors.highContrast : FbColors.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: c.blue,
      primary: c.blue,
      onPrimary: Colors.white,
      primaryContainer: c.blueSoft,
      onPrimaryContainer: c.blueStrong,
      error: c.red,
      errorContainer: c.redSoft,
      surface: c.card,
      onSurface: c.ink,
      onSurfaceVariant: c.muted,
      outline: c.line,
      outlineVariant: c.line,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: fontFamily);
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
    return base.copyWith(
      scaffoldBackgroundColor: c.bg,
      extensions: [c],
      textTheme: base.textTheme.apply(
        bodyColor: c.ink,
        displayColor: c.ink,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
      ),
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: c.faint, fontSize: 16),
        border: border(c.line),
        enabledBorder: border(highContrast ? c.ink2 : c.line),
        focusedBorder: border(c.blue, 2),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.blue,
        inactiveTrackColor: c.soft,
        thumbColor: c.blue,
        overlayColor: c.blue.withValues(alpha: .12),
        trackHeight: 6,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

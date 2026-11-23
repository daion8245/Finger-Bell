import 'package:flutter/material.dart';

/// 색 토큰. 인디고(blue*)는 기본 동작, 코랄(red*)은 SOS·위험에만 씁니다.
@immutable
class FbColors extends ThemeExtension<FbColors> {
  final Color blue;
  final Color blueStrong;
  final Color blueSoft;
  final Color red;
  final Color redStrong;
  final Color redSoft;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color faint;
  final Color line;
  final Color bg;
  final Color card;
  final Color soft;
  final Color glass;
  final Color navIdle;
  final Color backdrop;

  /// 카드 외곽선 (없으면 null). 기본은 1px, 고대비는 [cardBorderWidth] 2px.
  final Color? cardBorder;
  final double cardBorderWidth;

  const FbColors({
    required this.blue,
    required this.blueStrong,
    required this.blueSoft,
    required this.red,
    required this.redStrong,
    required this.redSoft,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.faint,
    required this.line,
    required this.bg,
    required this.card,
    required this.soft,
    required this.glass,
    required this.navIdle,
    required this.backdrop,
    this.cardBorder,
    this.cardBorderWidth = 1,
  });

  // 피그마 「핑거벨 · 공통 토큰」: primary 인디고, error 코랄, background #F4F5FB, outline #E6E8F0.
  static const light = FbColors(
    blue: Color(0xFF4F46E5),
    blueStrong: Color(0xFF4338CA),
    blueSoft: Color(0xFFEEF0FF),
    red: Color(0xFFFF5B4D),
    redStrong: Color(0xFFD63A2F),
    redSoft: Color(0xFFFFEEEC),
    ink: Color(0xFF1B1D2A),
    ink2: Color(0xFF3F4354),
    muted: Color(0xFF6B7080),
    faint: Color(0xFFA0A4B3),
    line: Color(0xFFE6E8F0),
    bg: Color(0xFFF4F5FB),
    card: Color(0xFFFFFFFF),
    soft: Color(0xFFEEEFF5),
    glass: Color(0xF2FFFFFF),
    navIdle: Color(0xFF9A9EAD),
    backdrop: Color(0xFFE9EBF3),
    cardBorder: Color(0xFFE6E8F0),
  );

  static const highContrast = FbColors(
    blue: Color(0xFF3730A3),
    blueStrong: Color(0xFF282380),
    blueSoft: Color(0xFFE0E3FF),
    red: Color(0xFFC8102E),
    redStrong: Color(0xFF9E0B22),
    redSoft: Color(0xFFFFE3E7),
    ink: Color(0xFF000000),
    ink2: Color(0xFF14181E),
    muted: Color(0xFF2E353F),
    faint: Color(0xFF4A525C),
    line: Color(0xFF8A929C),
    bg: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    soft: Color(0xFFE6EAEF),
    glass: Color(0xF5FFFFFF),
    navIdle: Color(0xFF4A525C),
    backdrop: Color(0xFFFFFFFF),
    cardBorder: Color(0xFF1B1F24),
    cardBorderWidth: 2,
  );

  static FbColors of(BuildContext context) => Theme.of(context).extension<FbColors>() ?? light;

  @override
  FbColors copyWith() => this;

  @override
  FbColors lerp(ThemeExtension<FbColors>? other, double t) {
    if (other is! FbColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return FbColors(
      blue: l(blue, other.blue),
      blueStrong: l(blueStrong, other.blueStrong),
      blueSoft: l(blueSoft, other.blueSoft),
      red: l(red, other.red),
      redStrong: l(redStrong, other.redStrong),
      redSoft: l(redSoft, other.redSoft),
      ink: l(ink, other.ink),
      ink2: l(ink2, other.ink2),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      line: l(line, other.line),
      bg: l(bg, other.bg),
      card: l(card, other.card),
      soft: l(soft, other.soft),
      glass: l(glass, other.glass),
      navIdle: l(navIdle, other.navIdle),
      backdrop: l(backdrop, other.backdrop),
      cardBorder: t < .5 ? cardBorder : other.cardBorder,
      cardBorderWidth: t < .5 ? cardBorderWidth : other.cardBorderWidth,
    );
  }
}

extension FbColorsContext on BuildContext {
  FbColors get fb => FbColors.of(this);
}

import 'package:flutter/material.dart';

/// 색 토큰 (Figma "핑거벨 · 공통 토큰").
/// - blue*: 기본 동작 (Figma primary, 남보라). 이름은 기존 코드와 맞추려고 그대로 둡니다.
/// - red*: SOS·위험·보류 (Figma error).
/// - warning*: 주의 모드 (Figma warning).
/// - teal*: 안전·완료 (Figma tertiary).
/// *Strong 색은 흰 바탕·*Soft 바탕 위 글자로 4.5:1 이상 대비가 나오게 고른 값입니다.
@immutable
class FbColors extends ThemeExtension<FbColors> {
  final Color blue;
  final Color blueStrong;
  final Color blueSoft;
  final Color red;
  final Color redStrong;
  final Color redSoft;
  final Color warning;
  final Color warningStrong;
  final Color warningSoft;
  final Color teal;
  final Color tealStrong;
  final Color tealSoft;
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

  /// 고대비 모드에서 카드에 두르는 테두리 (없으면 null).
  final Color? cardBorder;

  const FbColors({
    required this.blue,
    required this.blueStrong,
    required this.blueSoft,
    required this.red,
    required this.redStrong,
    required this.redSoft,
    required this.warning,
    required this.warningStrong,
    required this.warningSoft,
    required this.teal,
    required this.tealStrong,
    required this.tealSoft,
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
  });

  static const light = FbColors(
    blue: Color(0xFF5145E7),
    blueStrong: Color(0xFF3B30C4),
    blueSoft: Color(0xFFEEF0FD),
    red: Color(0xFFFB5D4D),
    redStrong: Color(0xFFC8321F),
    redSoft: Color(0xFFFFEEEB),
    warning: Color(0xFFF3A527),
    warningStrong: Color(0xFF8A5000),
    warningSoft: Color(0xFFFFF5DF),
    teal: Color(0xFF12B6A6),
    tealStrong: Color(0xFF0A766C),
    tealSoft: Color(0xFFE3F7F5),
    ink: Color(0xFF1C1D2B),
    ink2: Color(0xFF3F4354),
    muted: Color(0xFF6B7080),
    faint: Color(0xFF7C8191),
    line: Color(0xFFE5E9EF),
    bg: Color(0xFFF4F5FB),
    card: Color(0xFFFFFFFF),
    soft: Color(0xFFF1F2F9),
    glass: Color(0xFFFFFFFF),
    navIdle: Color(0xFF6B7080),
    backdrop: Color(0xFFECEEF6),
  );

  static const highContrast = FbColors(
    blue: Color(0xFF2E22B0),
    blueStrong: Color(0xFF1E1585),
    blueSoft: Color(0xFFE4E2FF),
    red: Color(0xFFC8102E),
    redStrong: Color(0xFF9E0B22),
    redSoft: Color(0xFFFFE3E7),
    warning: Color(0xFFB86E00),
    warningStrong: Color(0xFF6B3E00),
    warningSoft: Color(0xFFFFEFC7),
    teal: Color(0xFF0A766C),
    tealStrong: Color(0xFF075A52),
    tealSoft: Color(0xFFD5F2EE),
    ink: Color(0xFF000000),
    ink2: Color(0xFF14181E),
    muted: Color(0xFF2E353F),
    faint: Color(0xFF4A525C),
    line: Color(0xFF8A929C),
    bg: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    soft: Color(0xFFE6E8F0),
    glass: Color(0xFFFFFFFF),
    navIdle: Color(0xFF4A525C),
    backdrop: Color(0xFFFFFFFF),
    cardBorder: Color(0xFF1B1F24),
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
      warning: l(warning, other.warning),
      warningStrong: l(warningStrong, other.warningStrong),
      warningSoft: l(warningSoft, other.warningSoft),
      teal: l(teal, other.teal),
      tealStrong: l(tealStrong, other.tealStrong),
      tealSoft: l(tealSoft, other.tealSoft),
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
    );
  }
}

extension FbColorsContext on BuildContext {
  FbColors get fb => FbColors.of(this);
}

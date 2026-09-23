import 'package:flutter/material.dart';

/// eBarangay Mo color tokens (from the design system's tokens.json).
/// Read them in widgets with `context.colors.primary`, etc.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.border,
    required this.primary,
    required this.primaryStrong,
    required this.primarySoft,
    required this.onPrimary,
    required this.success,
    required this.danger,
    required this.cardShadow,
  });

  /// Screen background.
  final Color surface;

  /// Cards, sheets, inputs on surface.
  final Color surfaceRaised;

  /// Primary text and icons.
  final Color ink;

  /// Secondary text, captions, helper text, input borders.
  final Color inkMuted;

  /// Hairline dividers and card outlines (decorative only).
  final Color border;

  /// Maroon, the one brand accent: primary buttons, links, selected states.
  final Color primary;

  /// Pressed / hover state of primary.
  final Color primaryStrong;

  /// Selected rows, info banners, chips, "Pending". Put primary text on it.
  final Color primarySoft;

  /// Text and icons on primary, success and danger.
  final Color onPrimary;

  /// Approved, ready, paid, resolved.
  final Color success;

  /// Errors, rejected, emergency. Always paired with a word or icon.
  final Color danger;

  /// shadow-card: the only elevation, for floating cards and sheets.
  final List<BoxShadow> cardShadow;

  static const light = AppColors(
    surface: Color(0xFFF4F2F2),
    surfaceRaised: Color(0xFFFCFBFB),
    ink: Color(0xFF1B1618),
    inkMuted: Color(0xFF625A5D),
    border: Color(0xFFE3DDDE),
    primary: Color(0xFF6E1423),
    primaryStrong: Color(0xFF4F0E19),
    primarySoft: Color(0xFFF3E4E6),
    onPrimary: Color(0xFFFCFBFB),
    success: Color(0xFF1E6B4B),
    danger: Color(0xFFC0392B),
    cardShadow: [
      BoxShadow(
          color: Color(0x0F4E0E19), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(
          color: Color(0x0F4E0E19), offset: Offset(0, 8), blurRadius: 24),
    ],
  );

  static const dark = AppColors(
    surface: Color(0xFF141012),
    surfaceRaised: Color(0xFF1E191B),
    ink: Color(0xFFF3EEEF),
    inkMuted: Color(0xFFACA2A6),
    border: Color(0xFF342C2F),
    primary: Color(0xFFE0808E),
    primaryStrong: Color(0xFFEDA3AE),
    primarySoft: Color(0xFF3B1A20),
    onPrimary: Color(0xFF1B1618),
    success: Color(0xFF6FC79B),
    danger: Color(0xFFFF8F80),
    cardShadow: [
      BoxShadow(
          color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2),
    ],
  );

  @override
  AppColors copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? ink,
    Color? inkMuted,
    Color? border,
    Color? primary,
    Color? primaryStrong,
    Color? primarySoft,
    Color? onPrimary,
    Color? success,
    Color? danger,
    List<BoxShadow>? cardShadow,
  }) {
    return AppColors(
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      primaryStrong: primaryStrong ?? this.primaryStrong,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimary: onPrimary ?? this.onPrimary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryStrong: Color.lerp(primaryStrong, other.primaryStrong, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  /// The eBarangay Mo color tokens for the current theme (light or dark).
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppColors.dark
          : AppColors.light);
}

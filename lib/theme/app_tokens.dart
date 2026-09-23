/// Spacing tokens (4px base).
abstract final class AppSpace {
  /// Icon-to-label gaps.
  static const double s1 = 4;

  /// Gaps inside a row; pill padding.
  static const double s2 = 8;

  /// Between stacked cards in a list.
  static const double s3 = 12;

  /// Card padding and the screen gutter.
  static const double s4 = 16;

  /// Between sections of a screen.
  static const double s6 = 24;

  /// Top of a screen; empty-state breathing room.
  static const double s8 = 32;
}

/// Radius tokens. Inputs and chips: sm. Buttons and cards: md.
/// Sheets: lg. Status pills and avatars only: full.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 24;
  static const double full = 9999;
}

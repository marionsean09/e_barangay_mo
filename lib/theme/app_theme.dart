import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:e_barangay_mo/theme/app_colors.dart';
import 'package:e_barangay_mo/theme/app_tokens.dart';

/// Builds the eBarangay Mo light and dark themes.
///
/// Text styles from the design system map to Flutter's TextTheme:
///   display  → headlineMedium   (one per screen)
///   title    → titleLarge       (card and sheet headings)
///   subtitle → titleMedium      (list row titles, button labels)
///   body     → bodyLarge / bodyMedium
///   caption  → bodySmall        (dates, reference numbers, in ink-muted)
///   label    → labelMedium      (status pills)
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primarySoft,
      onPrimaryContainer: c.primary,
      secondary: c.primary,
      onSecondary: c.onPrimary,
      secondaryContainer: c.primarySoft,
      onSecondaryContainer: c.primary,
      tertiary: c.success,
      onTertiary: c.onPrimary,
      error: c.danger,
      onError: c.onPrimary,
      surface: c.surfaceRaised,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.surfaceRaised,
      surfaceContainerLow: c.surfaceRaised,
      surfaceContainer: c.surfaceRaised,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.inkMuted,
      outlineVariant: c.border,
      inverseSurface: c.ink,
      onInverseSurface: c.surface,
      inversePrimary: c.primarySoft,
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
    );

    final textTheme = _textTheme(c);

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    const buttonSize = Size(64, 48);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [c],
      textTheme: textTheme,
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surfaceRaised,
      dividerColor: c.border,
      iconTheme: IconThemeData(color: c.ink, size: 24),

      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        shape: Border(bottom: BorderSide(color: c.border)),
      ),

      cardTheme: CardThemeData(
        color: c.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: c.border),
        ),
      ),

      // Primary button: maroon, 48px tall, radius-md, subtitle label.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(buttonShape),
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSpace.s6)),
          textStyle: WidgetStatePropertyAll(textTheme.titleMedium),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return c.primary.withValues(alpha: 0.45);
            }
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return c.primaryStrong;
            }
            return c.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled)
                  ? c.onPrimary.withValues(alpha: 0.8)
                  : c.onPrimary),
          iconColor: WidgetStatePropertyAll(c.onPrimary),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),

      // Secondary button: outlined in maroon.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary),
          textStyle: textTheme.titleMedium,
        ),
      ),

      // Quiet / link-style actions.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          shape: buttonShape,
          textStyle: textTheme.titleMedium,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.ink),
      ),

      // Inputs: radius-sm, ink-muted border, maroon when focused.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s4, vertical: 14),
        border: inputBorder(c.inkMuted),
        enabledBorder: inputBorder(c.inkMuted),
        focusedBorder: inputBorder(c.primary, 2),
        errorBorder: inputBorder(c.danger),
        focusedErrorBorder: inputBorder(c.danger, 2),
        labelStyle: textTheme.bodyLarge?.copyWith(color: c.inkMuted),
        floatingLabelStyle: textTheme.bodyLarge?.copyWith(color: c.primary),
        hintStyle: textTheme.bodyLarge?.copyWith(color: c.inkMuted),
        prefixIconColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.focused) ? c.primary : c.inkMuted),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: c.surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.ink,
        textColor: c.ink,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyLarge,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceRaised,
        textStyle: textTheme.bodyLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: c.border),
        ),
      ),
    );
  }

  static TextTheme _textTheme(AppColors c) {
    TextStyle style(double size, double lineHeight, FontWeight weight,
            [double letterSpacingEm = 0]) =>
        TextStyle(
          fontSize: size,
          height: lineHeight / size,
          fontWeight: weight,
          letterSpacing: letterSpacingEm * size,
          color: c.ink,
        );

    final display = style(30, 36, FontWeight.w600, -0.02);
    final title = style(20, 28, FontWeight.w600, -0.01);
    final subtitle = style(16, 24, FontWeight.w500);
    final body = style(15, 22, FontWeight.w400);
    final caption =
        style(13, 18, FontWeight.w400).copyWith(color: c.inkMuted);
    final label = style(12, 16, FontWeight.w500);

    return GoogleFonts.geistTextTheme(
      TextTheme(
        displayLarge: display,
        displayMedium: display,
        displaySmall: display,
        headlineLarge: display,
        headlineMedium: display,
        headlineSmall: title,
        titleLarge: title,
        titleMedium: subtitle,
        titleSmall: subtitle,
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: subtitle,
        labelMedium: label,
        labelSmall: label,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'command_colors.dart';

/// Minimal, Calm Command Theme definition for Project Manager
class CommandTheme {
  static const String fontSans = 'Segoe UI';
  static const String fontMono = 'Consolas';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: CommandColors.background,
      canvasColor: CommandColors.surfaceBase,
      cardColor: CommandColors.surfaceCard,
      dividerColor: CommandColors.borderSubtle,
      fontFamily: fontSans,
      colorScheme: const ColorScheme.light(
        primary: CommandColors.signalIce,
        onPrimary: Colors.white,
        secondary: CommandColors.signalEmerald,
        onSecondary: Colors.white,
        surface: CommandColors.surfaceCard,
        onSurface: CommandColors.textPrimary,
        error: CommandColors.signalCoral,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CommandColors.surfaceBase,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fontSans,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: CommandColors.textPrimary,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: CommandColors.surfaceBase,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: CommandColors.borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CommandColors.surfaceBase,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: CommandColors.borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: CommandColors.borderMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: CommandColors.signalIce, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: CommandColors.textDisabled,
          fontSize: 13,
        ),
        labelStyle: const TextStyle(
          color: CommandColors.textSecondary,
          fontSize: 13,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: CommandColors.textPrimary,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontFamily: fontMono,
        ),
      ),
    );
  }

  // Common typography styles
  static const TextStyle titleMono = TextStyle(
    fontFamily: fontMono,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: CommandColors.textPrimary,
  );

  static const TextStyle telemetryLabel = TextStyle(
    fontFamily: fontMono,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: CommandColors.textMuted,
  );

  static const TextStyle telemetryValue = TextStyle(
    fontFamily: fontMono,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: CommandColors.textPrimary,
  );

  static const TextStyle bodyRegular = TextStyle(
    fontFamily: fontSans,
    fontSize: 13,
    color: CommandColors.textSecondary,
    height: 1.4,
  );
}

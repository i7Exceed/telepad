// SPDX-License-Identifier: MIT
// Copyright (c) 2026 i7Exceed. All rights reserved.
// TelePad - Wireless Physical Controller Relay & Virtual Gamepad Hub

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TelePadSemanticColors extends ThemeExtension<TelePadSemanticColors> {
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;
  final Color logSurface;
  final Color borderSubtle;

  const TelePadSemanticColors({
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
    required this.logSurface,
    required this.borderSubtle,
  });

  @override
  TelePadSemanticColors copyWith({
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? danger,
    Color? dangerBg,
    Color? logSurface,
    Color? borderSubtle,
  }) {
    return TelePadSemanticColors(
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      logSurface: logSurface ?? this.logSurface,
      borderSubtle: borderSubtle ?? this.borderSubtle,
    );
  }

  @override
  TelePadSemanticColors lerp(
    covariant ThemeExtension<TelePadSemanticColors>? other,
    double t,
  ) {
    if (other is! TelePadSemanticColors) return this;
    return TelePadSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      logSurface: Color.lerp(logSurface, other.logSurface, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
    );
  }
}

class GamepadTheme {
  final String id;
  final String name;
  final Brightness brightness;
  final Color bg;
  final Color bgCard;
  final Color bgField;
  final Color bgLog;
  final Color accent;
  final Color onAccent;
  final Color accentDim;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color danger;

  final Color btnA;
  final Color btnB;
  final Color btnX;
  final Color btnY;

  final Color dpad;
  final Color dpadHi;
  final Color joyBase;
  final Color joyKnob;
  final Color bumper;
  final Color bumperHi;

  const GamepadTheme({
    required this.id,
    required this.name,
    required this.brightness,
    required this.bg,
    required this.bgCard,
    required this.bgField,
    required this.bgLog,
    required this.accent,
    required this.onAccent,
    required this.accentDim,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.btnA,
    required this.btnB,
    required this.btnX,
    required this.btnY,
    required this.dpad,
    required this.dpadHi,
    required this.joyBase,
    required this.joyKnob,
    required this.bumper,
    required this.bumperHi,
  });
}

class C {
  C._();

  static final List<GamepadTheme> themes = [
    // 1. CYBER NEON (Dark Default - Deep Obsidian & High-Contrast Cyan)
    const GamepadTheme(
      id: 'cyber_neon',
      name: 'Cyber Neon',
      brightness: Brightness.dark,
      bg: Color(0xFF080B12),
      bgCard: Color(0xFF111827),
      bgField: Color(0xFF0C1220),
      bgLog: Color(0xFF05080F),
      accent: Color(0xFF00E5FF),
      onAccent: Color(0xFF041318),
      accentDim: Color(0xFF0891B2),
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFFCBD5E1),
      textMuted: Color(0xFF94A3B8),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFBBF24),
      danger: Color(0xFFFB7185),
      btnA: Color(0xFF22C55E),
      btnB: Color(0xFFFB7185),
      btnX: Color(0xFF38BDF8),
      btnY: Color(0xFFFACC15),
      dpad: Color(0xFF182238),
      dpadHi: Color(0xFF243454),
      joyBase: Color(0xFF0E1525),
      joyKnob: Color(0xFF253554),
      bumper: Color(0xFF162034),
      bumperHi: Color(0xFF243454),
    ),
    // 2. COBALT SLATE (Dark - Clean Material Tech)
    const GamepadTheme(
      id: 'cobalt_slate',
      name: 'Cobalt Slate',
      brightness: Brightness.dark,
      bg: Color(0xFF0A0E17),
      bgCard: Color(0xFF141C2E),
      bgField: Color(0xFF0E1424),
      bgLog: Color(0xFF070A12),
      accent: Color(0xFF38BDF8),
      onAccent: Color(0xFF061624),
      accentDim: Color(0xFF0284C7),
      textPrimary: Color(0xFFF1F5F9),
      textSecondary: Color(0xFFCBD5E1),
      textMuted: Color(0xFF94A3B8),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFBBF24),
      danger: Color(0xFFF87171),
      btnA: Color(0xFF34D399),
      btnB: Color(0xFFF87171),
      btnX: Color(0xFF60A5FA),
      btnY: Color(0xFFFDE047),
      dpad: Color(0xFF1E293B),
      dpadHi: Color(0xFF334155),
      joyBase: Color(0xFF111827),
      joyKnob: Color(0xFF2B3B55),
      bumper: Color(0xFF182234),
      bumperHi: Color(0xFF2B3B55),
    ),
    // 3. CARBON ONYX (Dark - Stealth Charcoal & Amber)
    const GamepadTheme(
      id: 'carbon_onyx',
      name: 'Carbon Onyx',
      brightness: Brightness.dark,
      bg: Color(0xFF0D0D0F),
      bgCard: Color(0xFF18181B),
      bgField: Color(0xFF121215),
      bgLog: Color(0xFF070709),
      accent: Color(0xFFFBBF24),
      onAccent: Color(0xFF1A1100),
      accentDim: Color(0xFFD97706),
      textPrimary: Color(0xFFFAFAFA),
      textSecondary: Color(0xFFD4D4D8),
      textMuted: Color(0xFFA1A1AA),
      success: Color(0xFF4ADE80),
      warning: Color(0xFFFBBF24),
      danger: Color(0xFFFB7185),
      btnA: Color(0xFFFBBF24),
      btnB: Color(0xFFFB7185),
      btnX: Color(0xFF60A5FA),
      btnY: Color(0xFFFDE68A),
      dpad: Color(0xFF27272A),
      dpadHi: Color(0xFF3F3F46),
      joyBase: Color(0xFF141417),
      joyKnob: Color(0xFF34343A),
      bumper: Color(0xFF222226),
      bumperHi: Color(0xFF36363C),
    ),
    // 4. DAYLIGHT SLATE (First-Class Light Appearance with >= 4.5:1 WCAG AA Contrast)
    const GamepadTheme(
      id: 'daylight_slate',
      name: 'Daylight',
      brightness: Brightness.light,
      bg: Color(0xFFF1F5F9),
      bgCard: Color(0xFFFFFFFF),
      bgField: Color(0xFFE2E8F0),
      bgLog: Color(0xFFF8FAFC),
      accent: Color(0xFF0369A1),
      onAccent: Color(0xFFFFFFFF),
      accentDim: Color(0xFF075985),
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF334155),
      textMuted: Color(0xFF475569),
      success: Color(0xFF15803D),
      warning: Color(0xFFB45309),
      danger: Color(0xFFBE123C),
      btnA: Color(0xFF15803D),
      btnB: Color(0xFFBE123C),
      btnX: Color(0xFF1D4ED8),
      btnY: Color(0xFFA16207),
      dpad: Color(0xFFE2E8F0),
      dpadHi: Color(0xFFCBD5E1),
      joyBase: Color(0xFFE2E8F0),
      joyKnob: Color(0xFF94A3B8),
      bumper: Color(0xFFE2E8F0),
      bumperHi: Color(0xFFCBD5E1),
    ),
  ];

  static final ValueNotifier<int> activeThemeIndex = ValueNotifier<int>(0);
  static final ValueNotifier<String> hapticIntensity =
      ValueNotifier<String>('Medium');
  static final ValueNotifier<double> deadzone = ValueNotifier<double>(0.08);

  static GamepadTheme get current {
    final idx = activeThemeIndex.value;
    if (idx < 0 || idx >= themes.length) return themes[0];
    return themes[idx];
  }

  /// Honors Android's "Remove animations" accessibility preference.
  static Duration motionDuration(BuildContext context, int ms) {
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duration(milliseconds: ms);
  }

  // Semantic Token Pointers (backed by active GamepadTheme for custom painters)
  static Color get bg => current.bg;
  static Color get bgCard => current.bgCard;
  static Color get bgField => current.bgField;
  static Color get bgLog => current.bgLog;

  static Color get cyan => current.accent;
  static Color get onAccent => current.onAccent;
  static Color get cyanDim => current.accentDim;
  static const purple = Color(0xFFC084FC);
  static Color get magenta => current.danger;
  static Color get green => current.success;
  static Color get amber => current.warning;
  static Color get red => current.danger;

  static Color get t1 => current.textPrimary;
  static Color get t2 => current.textSecondary;
  static Color get t3 => current.textMuted;

  static Color get btnA => current.btnA;
  static Color get btnB => current.btnB;
  static Color get btnX => current.btnX;
  static Color get btnY => current.btnY;

  static Color get dpad => current.dpad;
  static Color get dpadHi => current.dpadHi;
  static Color get joyBase => current.joyBase;
  static Color get joyKnob => current.joyKnob;
  static Color get bumper => current.bumper;
  static Color get bumperHi => current.bumperHi;

  static Color get glassCard => current.bgCard;
  static Color get glassBorder => current.brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.16)
      : Colors.black.withValues(alpha: 0.14);
  static Color get cyanBorder => current.accent.withValues(alpha: 0.45);
  static Color get cyanGlow => current.accent.withValues(alpha: 0.16);
  static Color get cyanGlowStrong => current.accent.withValues(alpha: 0.35);
  static Color get cyanHalf => current.accent.withValues(alpha: 0.70);
  static Color get cyanGlowSoft => current.accent.withValues(alpha: 0.10);
  static Color get purpleGlow => purple.withValues(alpha: 0.16);
  static Color get magentaGlow => current.danger.withValues(alpha: 0.14);

  static Color get greenGlow => current.success.withValues(alpha: 0.35);
  static Color get greenBg => current.success.withValues(alpha: 0.14);
  static Color get amberBg => current.warning.withValues(alpha: 0.15);
  static Color get redBg => current.danger.withValues(alpha: 0.14);
  static Color get redDim => current.danger.withValues(alpha: 0.65);

  static Color get t3Hint => current.textMuted;
  static Color get t3Dim => current.textMuted;
  static Color get t3VeryDim => current.textMuted.withValues(alpha: 0.85);
  static Color get t3Ghost => current.textMuted.withValues(alpha: 0.25);

  static Color get t3Faint => current.textMuted.withValues(alpha: 0.30);
  static Color get t3Super => current.textMuted;
  static Color get t3Micro => current.textMuted.withValues(alpha: 0.20);

  static Color get bgCardDim => current.bgField;
  static Color get cyanBorderLo => current.accent.withValues(alpha: 0.20);

  /// Material 3 ThemeData derived from the active GamepadTheme tokens.
  static ThemeData toMaterialTheme() {
    final t = current;
    final isDark = t.brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: t.brightness,
      primary: t.accent,
      onPrimary: t.onAccent,
      primaryContainer: t.accent.withValues(alpha: isDark ? 0.18 : 0.14),
      onPrimaryContainer: t.accent,
      secondary: isDark ? purple : t.accentDim,
      onSecondary: isDark ? const Color(0xFF1B0730) : Colors.white,
      surface: t.bgCard,
      onSurface: t.textPrimary,
      onSurfaceVariant: t.textSecondary,
      surfaceContainerLowest: t.bgLog,
      surfaceContainerLow: t.bg,
      surfaceContainer: t.bgCard,
      surfaceContainerHigh: t.bgField,
      surfaceContainerHighest: t.dpadHi,
      outline: isDark
          ? Colors.white.withValues(alpha: 0.22)
          : Colors.black.withValues(alpha: 0.20),
      outlineVariant: isDark
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.black.withValues(alpha: 0.12),
      error: t.danger,
      onError: Colors.white,
    );

    final semantic = TelePadSemanticColors(
      success: t.success,
      successBg: t.success.withValues(alpha: 0.14),
      warning: t.warning,
      warningBg: t.warning.withValues(alpha: 0.15),
      danger: t.danger,
      dangerBg: t.danger.withValues(alpha: 0.14),
      logSurface: t.bgLog,
      borderSubtle: scheme.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      extensions: [semantic],
      appBarTheme: AppBarTheme(
        backgroundColor: t.bgCard,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.bgCard,
        indicatorColor: t.accent.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: t.accent, size: 22);
          }
          return IconThemeData(color: t.textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? t.accent
                : t.textSecondary,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: t.bgCard,
        indicatorColor: t.accent.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: t.accent, size: 22),
        unselectedIconTheme: IconThemeData(color: t.textSecondary, size: 22),
        selectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: t.accent,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: t.textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? t.dpad : const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13),
        actionTextColor: isDark ? t.accent : const Color(0xFF38BDF8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.bgField,
        hintStyle: TextStyle(color: t.textMuted, fontSize: 13),
        labelStyle: TextStyle(color: t.textSecondary, fontSize: 13),
        errorStyle: TextStyle(color: t.danger, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.danger, width: 1.4),
        ),
      ),
      focusColor: t.accent.withValues(alpha: 0.16),
      highlightColor: Colors.transparent,
      splashColor: t.accent.withValues(alpha: 0.12),
    );
  }

  static void triggerHaptic(String type) {
    final intensity = hapticIntensity.value;
    if (intensity == 'Off') return;
    if (intensity == 'Light') {
      HapticFeedback.lightImpact();
    } else if (intensity == 'Medium') {
      if (type == 'selection') {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.mediumImpact();
      }
    } else if (intensity == 'Heavy') {
      HapticFeedback.vibrate();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta do BairroMatch — modo claro (coral + Plus Jakarta Sans).
class AppColors {
  static const coral = Color(0xFFE87A6F);
  static const coralLight = Color(0xFFFADDD9);
  static const coralDark = Color(0xFFD4503F);

  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF151A22);
  static const muted = Color(0xFFF2F3F5);
  static const mutedForeground = Color(0xFF7B8494);
  static const border = Color(0xFFE6E8EC);
  static const secondary = Color(0xFFF2F3F5);
  static const surfaceElevated = Color(0xFFFFFFFF);

  static const success = Color(0xFF33CC85);
  static const warning = Color(0xFFF5B341);
  static const destructive = Color(0xFFEF4444);
}

/// Paleta do BairroMatch — modo escuro.
/// Hierarquia de superfícies em cinza neutro (sem tint azul):
///   background (#121212) → surface/cards (#1E1E1E) → input (#2C2C2E)
class AppColorsDark {
  static const coral = Color(0xFFE87A6F);
  static const coralLight = Color(0xFF3D1E1A);
  static const coralDark = Color(0xFFD4503F);

  // Superfícies — profundidade crescente
  static const background = Color(0xFF121212);     // scaffold, tela de fundo
  static const surface = Color(0xFF1E1E1E);         // cards, bottom sheets, dialogs
  static const input = Color(0xFF2C2C2E);           // inputs, chips, campos de busca

  // Tipografia
  static const foreground = Color(0xFFFFFFFF);      // títulos e cabeçalhos (puro)
  static const mutedForeground = Color(0xFFA1A1A1); // corpo, placeholders, labels

  // Bordas sutis
  static const border = Color(0xFF3A3A3C);

  // Aliases mantidos para retrocompatibilidade com código existente
  static const muted = input;
  static const secondary = input;
  static const surfaceElevated = surface;

  static const success = Color(0xFF33CC85);
  static const warning = Color(0xFFF5B341);
  static const destructive = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.foreground, displayColor: AppColors.foreground);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.coral,
        onPrimary: Colors.white,
        secondary: AppColors.coral,
        onSecondary: Colors.white,
        surface: AppColors.background,
        onSurface: AppColors.foreground,
        onSurfaceVariant: AppColors.mutedForeground,
        surfaceContainerHighest: AppColors.secondary,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
        inverseSurface: AppColors.foreground,
        onInverseSurface: Colors.white,
        error: AppColors.destructive,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColors.mutedForeground.withValues(alpha: 0.7)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.coral,
        inactiveTrackColor: AppColors.secondary,
        thumbColor: AppColors.coral,
        overlayColor: Color(0x33E87A6F),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColorsDark.foreground,
      displayColor: AppColorsDark.foreground,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColorsDark.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.coral,
        onPrimary: Colors.white,
        secondary: AppColorsDark.coral,
        onSecondary: Colors.white,
        surface: AppColorsDark.surface,
        onSurface: AppColorsDark.foreground,
        onSurfaceVariant: AppColorsDark.mutedForeground,
        surfaceContainerHighest: AppColorsDark.input,
        outline: AppColorsDark.border,
        outlineVariant: AppColorsDark.border,
        inverseSurface: AppColorsDark.foreground,
        onInverseSurface: AppColorsDark.background,
        error: AppColorsDark.destructive,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Inputs numa camada acima dos cards
        fillColor: AppColorsDark.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColorsDark.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColorsDark.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColorsDark.coral, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColorsDark.mutedForeground.withValues(alpha: 0.8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.foreground,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColorsDark.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColorsDark.border),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColorsDark.coral,
        inactiveTrackColor: AppColorsDark.input,
        thumbColor: AppColorsDark.coral,
        overlayColor: const Color(0x33E87A6F),
      ),
    );
  }
}

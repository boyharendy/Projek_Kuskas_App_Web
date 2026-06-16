import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette - Premium Indigo/Purple
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Secondary palette - Cyan/Blue accents
  static const Color secondary = Color(0xFF0EA5E9); // Cyan
  static const Color secondaryLight = Color(0xFF38BDF8);
  static const Color secondaryDark = Color(0xFF0284C7);

  // Accent - Fuchsia/Pink for high-contrast highlights
  static const Color accent = Color(0xFFD946EF); // Fuchsia
  static const Color accentLight = Color(0xFFE879F9);

  // Background & Surface (PREMIUM DARK NAVY GRADIENT BASE)
  static const Color background = Color(0xFF05070F); // Deep Navy Black
  static const Color surface = Color(0xFF0E132D); // Lighter Navy
  static const Color surfaceVariant = Color(0xFF161B3D); // Elevated Surface
  static const Color cardBackground = Color(0x1F0F1532); // Translucent Dark Navy (Glassmorphism)

  // Text (PREMIUM SLATE & WHITE)
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure White
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textHint = Color(0xFF64748B); // Slate 500
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color incomeLight = Color(0xFF064E3B);
  static const Color expense = Color(0xFFEF4444); // Red
  static const Color expenseLight = Color(0xFF7F1D1D);
  static const Color balance = Color(0xFF3B82F6);
  static const Color balanceLight = Color(0xFF1E3A8A);

  // Utility
  static const Color divider = Color(0xFF1E293B); // Slate 800 Border
  static const Color border = Color(0xFF1E293B);
  static const Color shadow = Color(0x66000000);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const List<Color> primaryGradient = [Color(0xFF6366F1), Color(0xFF8B5CF6)]; // Indigo to Purple
  static const List<Color> secondaryGradient = [Color(0xFF0EA5E9), Color(0xFF3B82F6)]; // Cyan to Blue
  static const List<Color> accentGradient = [Color(0xFFD946EF), Color(0xFF6366F1)]; // Pink to Indigo
  static const List<Color> bgGradient = [Color(0xFF0B112C), Color(0xFF05070F)]; // Radial background gradient colors
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double round = 100;
}

class KuskasTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.textHint,
          fontSize: 12,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryLight,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.round),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
  static BoxDecoration get premiumBgDecoration => const BoxDecoration(
        gradient: RadialGradient(
          colors: AppColors.bgGradient,
          center: Alignment(0.0, -0.8),
          radius: 1.2,
        ),
      );

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnPrimary,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.textHint,
          fontSize: 12,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: const Color(0x1F0F1532), // Translucent card background
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 1), // Translucent white border
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x1F0F1532), // Translucent dark input
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x1F0F1532),
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.round),
        ),
        side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

class AppShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}

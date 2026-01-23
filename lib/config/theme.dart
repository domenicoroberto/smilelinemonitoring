import 'package:flutter/material.dart';

class AppColors {
  // Palette colori principali
  static const Color lightBlue = Color(0xFFB7D4E5);
  static const Color blue = Color(0xFF97BAD8);
  static const Color overlap = Color(0xFF8BB4C8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color graphite = Color(0xFF1A1A1A);

  // Colori derivati per compatibilità
  static const Color primary = blue;
  static const Color secondary = overlap;
  static const Color surface = white;
  static const Color background = lightBlue;

  // Colori di stato
  static const Color success = Color(0xFF8BB4C8);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color info = blue;

  // Colori di testo
  static const Color textPrimary = graphite;
  static const Color textSecondary = overlap;
  static const Color textHint = Color(0xFFBDC3C7);

  // Colori di bordo
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFFD0D0D0);

  // Colori overlay
  static const Color overlay = graphite;

  // Colori per chart/progress
  static const Color compliant = Color(0xFF8BB4C8);
  static const Color nonCompliant = Color(0xFFE74C3C);
  static const Color neutral = overlap;
}

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme - PRINCIPALE
      colorScheme: ColorScheme.light(
        primary: AppColors.blue,
        secondary: AppColors.overlap,
        tertiary: AppColors.lightBlue,
        surface: AppColors.white,
        error: AppColors.error,
        brightness: Brightness.light,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.white,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.graphite,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.graphite,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.graphite,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.graphite,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.graphite,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.graphite,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.graphite,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.graphite,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.graphite,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.overlap,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.graphite,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.graphite,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.overlap,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.blue,
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.overlap,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: AppColors.textHint,
        ),
      ),

      // ============ BUTTON THEMES ============
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue, // ✅ BLU
          foregroundColor: AppColors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue, // ✅ BLU
          side: const BorderSide(
            color: AppColors.blue,
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.blue,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue, // ✅ BLU
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.blue,
          ),
        ),
      ),

      // ============ INPUT DECORATION THEME ============
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightBlue.withOpacity(0.15),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.blue, // ✅ BLU
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        labelStyle: const TextStyle(
          color: AppColors.graphite,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),

      // ============ CARD THEME ============
      cardTheme: const CardThemeData(
        color: AppColors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.zero,
      ),

      // ============ DIVIDER THEME ============
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),

      // ============ BOTTOM NAVIGATION BAR THEME ============
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.blue, // ✅ BLU
        unselectedItemColor: AppColors.overlap,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // ============ DIALOG THEME ============
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // ============ FAB THEME ============
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.blue, // ✅ BLU
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ============ CHECKBOX THEME ============
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith(
              (states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.blue; // ✅ BLU
            }
            return AppColors.border;
          },
        ),
        side: const BorderSide(color: AppColors.border),
      ),

      // ============ RADIO THEME ============
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith(
              (states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.blue; // ✅ BLU
            }
            return AppColors.border;
          },
        ),
      ),

      // ============ SWITCH THEME ============
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
              (states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.blue; // ✅ BLU
            }
            return AppColors.overlap;
          },
        ),
        trackColor: MaterialStateProperty.resolveWith(
              (states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.blue.withOpacity(0.4); // ✅ BLU
            }
            return AppColors.border;
          },
        ),
      ),

      // ============ PROGRESS INDICATOR THEME ============
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blue, // ✅ BLU
        linearTrackColor: AppColors.border,
      ),

      // ============ SNACK BAR THEME ============
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.graphite,
        contentTextStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ============ SLIDER THEME ============
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.blue, // ✅ BLU
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.blue, // ✅ BLU
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.blue,
        secondary: AppColors.overlap,
        surface: const Color(0xFF1E1E1E),
        error: AppColors.error,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: AppColors.white,
      ),
    );
  }
}
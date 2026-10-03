import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // =============================================================
  // BRAND COLORS
  // =============================================================

  static const Color primary = Color(0xff7C4DFF);
  static const Color secondary = Color(0xffB388FF);
  static const Color accent = Color(0xff00E5FF);
  static const Color success = Color(0xff00C853);
  static const Color error = Color(0xffFF5252);

  // =============================================================
  // DARK COLORS
  // =============================================================

  static const Color darkBackground = Color(0xff0F0F0F);
  static const Color darkCard = Color(0xff1D1D1D);
  static const Color darkCard2 = Color(0xff262626);
  static const Color darkText = Colors.white;
  static const Color darkSubtitle = Color(0xffA0A0A0);
  static const Color darkBorder = Color(0xff353535);

  // =============================================================
  // LIGHT COLORS
  // =============================================================

  static const Color lightBackground = Color(0xffF5F5F5);
  static const Color lightCard = Colors.white;
  static const Color lightCard2 = Color(0xffEEEEEE);
  static const Color lightText = Color(0xff1A1A1A);
  static const Color lightSubtitle = Color(0xff616161);
  static const Color lightBorder = Color(0xffD8D2E0);

  // =============================================================
  // GRADIENTS
  // =============================================================

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xff22163D),
      darkBackground,
    ],
  );

  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xffEDE7F6),
      Colors.white,
    ],
  );

  // Brand artwork gradient stays consistent in both modes.
  static const LinearGradient albumGradient = LinearGradient(
    colors: [
      Color(0xff8E2DE2),
      Color(0xff4A00E0),
    ],
  );

  // =============================================================
  // BORDER RADIUS
  // =============================================================

  static const BorderRadius radius12 =
      BorderRadius.all(Radius.circular(12));

  static const BorderRadius radius18 =
      BorderRadius.all(Radius.circular(18));

  static const BorderRadius radius25 =
      BorderRadius.all(Radius.circular(25));

  static const BorderRadius radius30 =
      BorderRadius.all(Radius.circular(30));

  // =============================================================
  // TEXT STYLES
  // =============================================================

  static const TextStyle heading = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subHeading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // =============================================================
  // THEME DATA
  // =============================================================

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        background: lightBackground,
        card: lightCard,
        card2: lightCard2,
        text: lightText,
        subtitle: lightSubtitle,
        border: lightBorder,
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        background: darkBackground,
        card: darkCard,
        card2: darkCard2,
        text: darkText,
        subtitle: darkSubtitle,
        border: darkBorder,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color card,
    required Color card2,
    required Color text,
    required Color subtitle,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: background,
      primaryColor: primary,

      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
      ).copyWith(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: card,
        onSurface: text,
        outline: border,
        error: error,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: radius18,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(color: text),
        displayMedium: TextStyle(color: text),
        displaySmall: TextStyle(color: text),
        headlineLarge: TextStyle(color: text),
        headlineMedium: TextStyle(color: text),
        headlineSmall: TextStyle(color: text),
        titleLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(color: text),
        bodyLarge: TextStyle(color: text),
        bodyMedium: TextStyle(color: text),
        bodySmall: TextStyle(color: subtitle),
        labelLarge: TextStyle(color: text),
        labelMedium: TextStyle(color: subtitle),
        labelSmall: TextStyle(color: subtitle),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card2,
        hintStyle: TextStyle(color: subtitle),
        labelStyle: TextStyle(color: subtitle),
        prefixIconColor: subtitle,
        suffixIconColor: subtitle,
        enabledBorder: OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        border: const OutlineInputBorder(
          borderRadius: radius12,
        ),
      ),

      iconTheme: IconThemeData(color: text),

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return subtitle;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return border;
        }),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: border,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: .15),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: isDark ? .20 : .12),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected) ? primary : subtitle,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          );
        }),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: subtitle,
          fontSize: 15,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: radius18,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: card2,
        contentTextStyle: TextStyle(color: text),
        actionTextColor: primary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: radius12,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
    );
  }

  // =============================================================
  // CONTEXT-AWARE HELPERS USED BY ALL SCREENS
  // =============================================================

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color text(BuildContext context) {
    return isDark(context) ? darkText : lightText;
  }

  static Color subtitleColor(BuildContext context) {
    return isDark(context) ? darkSubtitle : lightSubtitle;
  }

  static Color card(BuildContext context) {
    return isDark(context) ? darkCard : lightCard;
  }

  static Color card2(BuildContext context) {
    return isDark(context) ? darkCard2 : lightCard2;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? darkBorder : lightBorder;
  }

  static Color shadow(BuildContext context) {
    return isDark(context)
        ? Colors.black.withValues(alpha: .35)
        : Colors.black.withValues(alpha: .10);
  }

  static Color surfaceOverlay(BuildContext context) {
    return isDark(context)
        ? Colors.white.withValues(alpha: .06)
        : Colors.black.withValues(alpha: .04);
  }

  static LinearGradient backgroundGradient(BuildContext context) {
    return isDark(context) ? darkGradient : lightGradient;
  }

  static BoxDecoration cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: card(context),
      borderRadius: radius18,
    );
  }

  static BoxDecoration glassDecoration(BuildContext context) {
    return BoxDecoration(
      color: surfaceOverlay(context),
      borderRadius: radius18,
    );
  }
}

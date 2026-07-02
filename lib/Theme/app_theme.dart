import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  //==========================
  // COLORS
  //==========================

  static const Color primary = Color(0xff7C4DFF);

  static const Color secondary = Color(0xffB388FF);

  static const Color accent = Color(0xff00E5FF);

  static const Color success = Color(0xff00C853);

  static const Color error = Color(0xffFF5252);

  //==========================
  // DARK COLORS
  //==========================

  static const Color darkBackground = Color(0xff0F0F0F);

  static const Color darkCard = Color(0xff1D1D1D);

  static const Color darkCard2 = Color(0xff262626);

  static const Color darkText = Colors.white;

  static const Color darkSubtitle = Color(0xffA0A0A0);

  //==========================
  // LIGHT COLORS
  //==========================

  static const Color lightBackground = Color(0xffF5F5F5);

  static const Color lightCard = Colors.white;

  static const Color lightCard2 = Color(0xffEEEEEE);

  static const Color lightText = Color(0xff1A1A1A);

  static const Color lightSubtitle = Color(0xff616161);

  //==========================
  // GRADIENTS
  //==========================

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xff22163D),
      Color(0xff0F0F0F),
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

  static const LinearGradient albumGradient = LinearGradient(
    colors: [
      Color(0xff8E2DE2),
      Color(0xff4A00E0),
    ],
  );

  //==========================
  // BORDER RADIUS
  //==========================

  static const BorderRadius radius12 =
      BorderRadius.all(Radius.circular(12));

  static const BorderRadius radius18 =
      BorderRadius.all(Radius.circular(18));

  static const BorderRadius radius25 =
      BorderRadius.all(Radius.circular(25));

  static const BorderRadius radius30 =
      BorderRadius.all(Radius.circular(30));

  //==========================
  // TEXT STYLE
  //==========================

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

  //==========================
  // LIGHT THEME
  //==========================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    brightness: Brightness.light,

    scaffoldBackgroundColor: lightBackground,

    primaryColor: primary,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),

    cardColor: lightCard,

    fontFamily: "Poppins",
  );

  //==========================
  // DARK THEME
  //==========================

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    brightness: Brightness.dark,

    scaffoldBackgroundColor: darkBackground,

    primaryColor: primary,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),

    cardColor: darkCard,

    fontFamily: "Poppins",
  );

  //==========================
  // HELPERS
  //==========================

  static Color text(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText
        : lightText;
  }

  static Color subtitleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSubtitle
        : lightSubtitle;
  }

  static Color card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : lightCard;
  }

  static Color card2(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard2
        : lightCard2;
  }

  static LinearGradient backgroundGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkGradient
        : lightGradient;
  }

  static BoxDecoration cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: card(context),
      borderRadius: radius18,
    );
  }

  static BoxDecoration glassDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(.06)
          : Colors.black.withOpacity(.04),
      borderRadius: radius18,
    );
  }
}
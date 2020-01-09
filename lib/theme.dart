import 'package:flutter/material.dart';

const PrimaryColor = const Color(0xFF004d40);
const PrimaryColorLight = const Color(0xFF39796b);
const PrimaryColorDark = const Color(0xFF00251a);

const SecondaryColor = const Color(0xFF26a69a);
const SecondaryColorLight = const Color(0xFF64d8cb);
const SecondaryColorDark = const Color(0xFF00766c);

const Background = const Color(0xFF004d40);
const DarkBackground = const Color(0xFF00251a);

const TextColor = const Color(0xFFFFFFFF);

class MyTheme {
  static final ThemeData defaultTheme = _buildTheme();

  static ThemeData _buildTheme() {
    final ThemeData base = ThemeData.light();

    return base.copyWith(
      accentColor: SecondaryColor,
      accentColorBrightness: Brightness.dark,

      primaryColor: PrimaryColor,
      primaryColorDark: PrimaryColorDark,
      primaryColorLight: PrimaryColorLight,
      primaryColorBrightness: Brightness.dark,

      buttonTheme: base.buttonTheme.copyWith(
        buttonColor: SecondaryColor,
        textTheme: ButtonTextTheme.primary,
      ),

      scaffoldBackgroundColor: Background,
      cardColor: Background,
      textSelectionColor: PrimaryColorLight,
      backgroundColor: Background,

      textTheme: base.textTheme.copyWith(
          title: base.textTheme.title.copyWith(color: TextColor),
          body1: base.textTheme.body1.copyWith(color: TextColor),
          body2: base.textTheme.body2.copyWith(color: TextColor)
      ),
    );



  }
}
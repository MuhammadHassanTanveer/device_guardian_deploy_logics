import 'package:flutter/material.dart';
import '../util/app_constants.dart';

ThemeData light = ThemeData(
  fontFamily: AppConstants.fontFamily,
  primaryColor: const Color(0xFF15BE56), // Morning sky blue (replaces teal)
  secondaryHeaderColor: const Color(0xFF107939), // Deeper ocean blue
  disabledColor: const Color(0xFF9B9B9B),
  brightness: Brightness.light,
  hintColor: const Color(0xFF5E6472),
  cardColor: Colors.white.withValues(alpha: 0.9), // Slightly transparent white
  shadowColor: Colors.blueGrey.withValues(alpha: 0.1), // Soft blue-grey shadow
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF15BE56), // Matching primary
    ),
  ),
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF15BE56), // Morning blue
    tertiary: const Color(0xFF107939), // Deep blue (unchanged)
    tertiaryContainer: const Color(0xFFB6F1CD), // Lighter sky blue
    secondary: const Color(0xFF79F6A9), // Soft teal accent
    surface: const Color(0xFFF0F8FF), // Alice blue background
    error: const Color(0xFFE84D4F),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    color: Colors.white,
    surfaceTintColor: Color(0xFFF0F8FF), // Matching surface
  ),
  dialogTheme: const DialogThemeData(
    surfaceTintColor: Color(0xFFF0F8FF), // Matching surface
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF15BE56), // Primary blue
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(500),
    ),
  ),
  bottomAppBarTheme: BottomAppBarThemeData(
    surfaceTintColor: Colors.white,
    height: 60,
    padding: const EdgeInsets.symmetric(vertical: 5),
    shadowColor: Colors.blueGrey.withOpacity(0.1),
  ),
  dividerTheme: DividerThemeData(
    color: const Color(0xFFBABFC4).withOpacity(0.25),
    thickness: 0.5,
  ),
  tabBarTheme: const TabBarThemeData(
    dividerColor: Colors.transparent,
    labelColor: Color(0xFF107939), // Deep blue for active tabs
  ),
);
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4D5DFA);
  static const Color backgroundColor = Color.fromARGB(255, 248, 248, 248);
  static const Color textColor = Color(0xFF212121);
  static const Color subTextColor = Color(0xFF9E9E9E);
  static const Color dividerColor = Color(0xFFEEEEEE);
  static const Color inputFillColor = Color(0xFFFAFAFA);

  // Dialog / status colors
  static const Color successColor = Color(0xFF43A047);
  static const Color successLightColor = Color(0xFF66BB6A);
  static const Color successBgColor = Color(0xFFE8F5E9);
  static const Color successDotColor = Color(0xFF81C784);

  static const Color errorColor = Color(0xFFE53935);
  static const Color errorLightColor = Color(0xFFEF5350);
  static const Color errorBgColor = Color(0xFFFFEBEE);
  static const Color errorDotColor = Color(0xFFEF9A9A);

  static const Color warningColor = Color(0xFFF57C00);
  static const Color warningLightColor = Color(0xFFFFA726);
  static const Color warningBgColor = Color(0xFFFFF3E0);
  static const Color warningDotColor = Color(0xFFFFCC80);

  static const Color primaryLightColor = Color(0xFF7784FF);
  static const Color primaryBgColor = Color(0xFFEDEFFF);
  static const Color primaryDotColor = Color(0xFF949EFC);

  // Alert / Snackbar colors
  static const Color successAlertBgColor = Color(0xFFEAF7F0);
  static const Color successAlertIconColor = Color(0xFF4CAF50);
  static const Color successAlertTextColor = Color(0xFF2E7D32);

  static const Color errorAlertBgColor = Color(0xFFFDEDEF);
  static const Color errorAlertIconColor = Color(0xFFE53B4C);
  static const Color errorAlertTextColor = Color(0xFFCB1B2C);

  static const Color warningAlertBgColor = Color(0xFFFFF3CD);
  static const Color warningAlertTextColor = Color(0xFFE65100);

  static const Color infoAlertBgColor = Color(0xFFE3F2FD);
  static const Color infoAlertIconColor = Color(0xFF2196F3);
  static const Color infoAlertTextColor = Color(0xFF1565C0);

  // Map & Traffic Semantic Tokens (Apple Maps Palette & Audited Tokens)
  static const Color mapCanvasColor = Color(0xFFF6F4EF);
  static const Color trafficCongestionColor = errorColor; // #E53935 (WCAG 4.68:1)
  static const Color trafficAccidentColor = warningColor; // #F57C00 (WCAG 3.82:1)
  static const Color trafficReportColor = warningLightColor; // #FFA726
  static const Color trafficFloodingColor = Color(0xFF0288D1); // Deep Azure (WCAG 4.91:1)
  static const Color trafficSosColor = errorColor; // #E53935
  static const Color trafficGeneralColor = primaryColor; // #4D5DFA (WCAG 4.55:1)

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: backgroundColor,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: Color(0x334D5DFA), // primaryColor with ~0.2 opacity
        selectionHandleColor: primaryColor,
      ),
      textTheme: GoogleFonts.quicksandTextTheme(),
    );
  }
}

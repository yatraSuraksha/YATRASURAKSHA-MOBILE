import 'package:flutter/material.dart';

/// App colors used throughout the Yatra Suraksha application
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFFF16C00);
  static const Color background = Colors.white;
  static const Color primaryText = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF545454);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFB00020);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Neutral colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Grey scale
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Primary color variations
  static const Color primaryLight = Color(0xFFFF9D3C);
  static const Color primaryDark = Color(0xFFB84A00);

  // Shadow colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x26000000);

  // Disabled colors
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color disabledText = Color(0xFF9E9E9E);

  // Surface colors
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color borderDark = Color(0xFFBDBDBD);

  // Focus and hover states
  static const Color focusColor = Color(0x1FF16C00);
  static const Color hoverColor = Color(0x0AF16C00);

  // Overlay colors
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // Travel-specific colors (optional, for travel app context)
  static const Color travelBlue = Color(0xFF1E88E5);
  static const Color travelGreen = Color(0xFF43A047);
  static const Color emergencyRed = Color(0xFFD32F2F);
  static const Color safetyYellow = Color(0xFFFFC107);
}

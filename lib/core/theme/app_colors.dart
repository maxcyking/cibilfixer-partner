import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary colors (matching Tailwind primary)
  static const Color primary50 = Color(0xFFFFFBEB);
  static const Color primary100 = Color(0xFFFEF3C7);
  static const Color primary200 = Color(0xFFFDE68A);
  static const Color primary300 = Color(0xFFFCD34D);
  static const Color primary400 = Color(0xFFFBBF24);
  static const Color primary500 = Color(0xFFF59E0B);
  static const Color primary600 = Color(0xFFD97706);
  static const Color primary700 = Color(0xFFB45309);
  static const Color primary800 = Color(0xFF92400E);
  static const Color primary900 = Color(0xFF78350F);

  // Secondary colors
  static const Color secondary50 = Color(0xFFF0F9FF);
  static const Color secondary100 = Color(0xFFE0F2FE);
  static const Color secondary200 = Color(0xFFBAE6FD);
  static const Color secondary300 = Color(0xFF7DD3FC);
  static const Color secondary400 = Color(0xFF38BDF8);
  static const Color secondary500 = Color(0xFF0EA5E9);
  static const Color secondary600 = Color(0xFF0284C7);
  static const Color secondary700 = Color(0xFF0369A1);
  static const Color secondary800 = Color(0xFF075985);
  static const Color secondary900 = Color(0xFF0C4A6E);

  // Neutral colors (matching Tailwind neutral/gray)
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);

  // Success colors
  static const Color success50 = Color(0xFFF0FDF4);
  static const Color success100 = Color(0xFFDCFCE7);
  static const Color success200 = Color(0xFFBBF7D0);
  static const Color success300 = Color(0xFF86EFAC);
  static const Color success400 = Color(0xFF4ADE80);
  static const Color success500 = Color(0xFF22C55E);
  static const Color success600 = Color(0xFF16A34A);
  static const Color success700 = Color(0xFF15803D);
  static const Color success800 = Color(0xFF166534);
  static const Color success900 = Color(0xFF14532D);

  // Error colors
  static const Color error50 = Color(0xFFFEF2F2);
  static const Color error100 = Color(0xFFFEE2E2);
  static const Color error200 = Color(0xFFFECACA);
  static const Color error300 = Color(0xFFFCA5A5);
  static const Color error400 = Color(0xFFF87171);
  static const Color error500 = Color(0xFFEF4444);
  static const Color error600 = Color(0xFFDC2626);
  static const Color error700 = Color(0xFFB91C1C);
  static const Color error800 = Color(0xFF991B1B);
  static const Color error900 = Color(0xFF7F1D1D);

  // Warning colors
  static const Color warning50 = Color(0xFFFFFBEB);
  static const Color warning100 = Color(0xFFFEF3C7);
  static const Color warning200 = Color(0xFFFDE68A);
  static const Color warning300 = Color(0xFFFCD34D);
  static const Color warning400 = Color(0xFFFBBF24);
  static const Color warning500 = Color(0xFFF59E0B);
  static const Color warning600 = Color(0xFFD97706);
  static const Color warning700 = Color(0xFFB45309);
  static const Color warning800 = Color(0xFF92400E);
  static const Color warning900 = Color(0xFF78350F);

  // Info colors
  static const Color info50 = Color(0xFFEFF6FF);
  static const Color info100 = Color(0xFFDBEAFE);
  static const Color info200 = Color(0xFFBFDBFE);
  static const Color info300 = Color(0xFF93BBFC);
  static const Color info400 = Color(0xFF60A5FA);
  static const Color info500 = Color(0xFF3B82F6);
  static const Color info600 = Color(0xFF2563EB);
  static const Color info700 = Color(0xFF1D4ED8);
  static const Color info800 = Color(0xFF1E40AF);
  static const Color info900 = Color(0xFF1E3A8A);

  // Background and surface colors
  static const Color background = neutral50;
  static const Color surface = Colors.white;
  static const Color surfaceVariant = neutral100;

  // Text colors
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral700;
  static const Color textTertiary = neutral500;
  static const Color textDisabled = neutral400;
  static const Color textInverse = Colors.white;

  // Border colors
  static const Color border = neutral200;
  static const Color borderLight = neutral100;
  static const Color borderDark = neutral300;

  // Shadow colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color shadowColorLight = Color(0x0D000000);
  static const Color shadowColorDark = Color(0x33000000);

  // Common shortcuts for easy access
  static const Color primary = primary500;
  static const Color secondary = secondary500;
  static const Color success = success500;
  static const Color error = error500;
  static const Color warning = warning500;
  static const Color info = info500;
  static const Color shadow = shadowColor;
} 
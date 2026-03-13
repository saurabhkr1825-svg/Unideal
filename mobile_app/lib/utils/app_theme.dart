import 'package:flutter/material.dart';

class AppTheme {
  // 1. Consistent Spacing System
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // borderRadius
  static const double radiusM = 12.0;
  static const double radiusL = 20.0;

  // 2. Official Brand Colors (Restricting to 3 Main Colors as Requested)
  static const Color primaryColor = Color(0xFF2E7D32); // Green
  static const Color secondaryColor = Colors.white; // White
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light grey background
  static const Color textPrimaryColor = Color(0xFF212121); // Dark Gray/Black
  static const Color textSecondaryColor = Colors.grey;

  // Contextual Badge Colors
  static const Color auctionColor = Colors.orange;
  static const Color donationColor = primaryColor;
  static const Color forSaleColor = Colors.blue;
  static const Color unidealIndigo = Colors.indigo; // Preserving original indigo for core accents where needed

  // 3. Typography System
  // Title → 18 bold
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  // Price → 16 bold
  static const TextStyle priceStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  // Body → 14
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: textPrimaryColor,
  );

  // Small info → 12 grey
  static const TextStyle smallInfoStyle = TextStyle(
    fontSize: 12,
    color: textSecondaryColor,
  );

  // Reusable ThemeData global
  static ThemeData get themeData {
    return ThemeData(
      fontFamily: 'Inter',
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          minimumSize: const Size(0, 48),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryColor,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
    );
  }
}

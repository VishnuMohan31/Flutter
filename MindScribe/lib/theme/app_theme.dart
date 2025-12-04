// Clean, Standard Material Design Theme
import 'package:flutter/material.dart';

class AppTheme {
  // Clean Standard Colors (Google Material Design)
  static const Color primaryBlue = Color(0xFF1976D2); // Material Blue 700
  static const Color primaryLight = Color(0xFF42A5F5); // Material Blue 400
  static const Color primaryDark = Color(0xFF0D47A1); // Material Blue 900
  
  static const Color accentTeal = Color(0xFF00897B); // Material Teal 600
  static const Color accentOrange = Color(0xFFFF6F00); // Material Orange 900
  static const Color accentGreen = Color(0xFF43A047); // Material Green 600
  static const Color accentPurple = Color(0xFF7B1FA2); // Material Purple 700
  static const Color accentAmber = Color(0xFFFFA000); // Material Amber 700
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA); // Light grey
  static const Color backgroundDark = Color(0xFF121212); // Material dark
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFFE0E0E0);
  
  // Status Colors (Material Design)
  static const Color successGreen = Color(0xFF4CAF50); // Material Green
  static const Color warningOrange = Color(0xFFFF9800); // Material Orange
  static const Color errorRed = Color(0xFFF44336); // Material Red
  static const Color infoBlue = Color(0xFF2196F3); // Material Blue
  
  // Priority Colors (Clean & Clear)
  static const Color priorityLow = Color(0xFF81C784); // Light Green
  static const Color priorityMedium = Color(0xFF64B5F6); // Light Blue
  static const Color priorityHigh = Color(0xFFFFB74D); // Light Orange
  static const Color priorityUrgent = Color(0xFFE57373); // Light Red
  
  // Category Colors (Standard Material Colors)
  static const Map<String, Color> categoryColors = {
    'Personal': Color(0xFF2196F3), // Blue
    'Work': Color(0xFFFF9800), // Orange
    'Health': Color(0xFF4CAF50), // Green
    'Finance': Color(0xFF9C27B0), // Purple
    'Education': Color(0xFF00BCD4), // Cyan
    'Travel': Color(0xFFF44336), // Red
    'Goals': Color(0xFFFFEB3B), // Yellow
    'Ideas': Color(0xFFE91E63), // Pink
  };

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: backgroundLight,
    
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: accentOrange,
      surface: cardLight,
      background: backgroundLight,
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onBackground: textPrimary,
      outline: Color(0xFFE0E0E0), // Border color
    ),
    
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ),
    
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      color: cardLight,
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: Colors.grey[500]),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200]!,
      selectedColor: primaryBlue.withOpacity(0.2),
      labelStyle: const TextStyle(fontSize: 12, color: textPrimary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[400]!, width: 1),
      ),
      elevation: 1,
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryBlue,
      unselectedItemColor: textSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: backgroundDark,
    
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: accentOrange,
      surface: cardDark,
      background: backgroundDark,
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textLight,
      onBackground: textLight,
    ),
    
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: cardDark,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ),
    
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardDark,
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: cardDark,
      selectedColor: primaryBlue.withOpacity(0.3),
      labelStyle: const TextStyle(fontSize: 12, color: textLight),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardDark,
      selectedItemColor: primaryBlue,
      unselectedItemColor: textSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );

  // Gradient Decorations
  static BoxDecoration gradientBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryBlue.withOpacity(0.1),
        accentPurple.withOpacity(0.05),
      ],
    ),
  );

  static BoxDecoration cardGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Colors.grey[50]!,
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );
}

import 'package:flutter/material.dart';

class AipaTheme {
  static const _primaryColor = Color(0xFF1565C0); // Donkerblauw
  static const _secondaryColor = Color(0xFFFF8F00); // Warm oranje
  static const _backgroundColor = Color(0xFFF5F5F5);
  static const _surfaceColor = Colors.white;
  static const _errorColor = Color(0xFFD32F2F);
  static const _onPrimaryColor = Colors.white;
  static const _textColor = Color(0xFF212121);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: _primaryColor,
          secondary: _secondaryColor,
          surface: _surfaceColor,
          error: _errorColor,
          onPrimary: _onPrimaryColor,
          onSurface: _textColor,
        ),
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryColor,
          foregroundColor: _onPrimaryColor,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _onPrimaryColor,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
          bodyLarge: TextStyle(
            fontSize: 20,
            height: 1.5,
            color: _textColor,
          ),
          bodyMedium: TextStyle(
            fontSize: 18,
            height: 1.4,
            color: _textColor,
          ),
          labelLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _onPrimaryColor,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(64, 64),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          hintStyle: const TextStyle(fontSize: 18, color: Colors.grey),
          filled: true,
          fillColor: _surfaceColor,
        ),
        iconTheme: const IconThemeData(size: 28),
      );
}

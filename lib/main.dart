import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const SpendWiseApp());
}

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const DashboardScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme - Premium Dark with Vibrant Accents
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF667EEA), // Vibrant purple-blue
        secondary: Color(0xFF764BA2), // Deep purple
        surface: Color(0xFF1A1A2E), // Dark blue-gray
        error: Color(0xFFEF4444), // Red
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFE5E7EB),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF1A1A2E),
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF0F0F1E),
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1A2E),
        selectedItemColor: Color(0xFF667EEA),
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF667EEA),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE5E7EB),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFFE5E7EB),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF9CA3AF),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        hintStyle: const TextStyle(color: Color(0xFF6B7280)),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF667EEA),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

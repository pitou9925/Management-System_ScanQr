import 'package:flutter/material.dart';
import 'screens/barcode_home_page.dart';

void main() {
  runApp(const BarcodeSystemApp());
}

class BarcodeSystemApp extends StatelessWidget {
  const BarcodeSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'បន្ទប់ពិគ្រោះ និងព្យាបាលជំងឺ ទ័ពមានជ័យ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFF4CAF50),
          surface: Colors.white,
          background: const Color(0xFFF8FAFC),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF1A1A1A),
          onBackground: const Color(0xFF1A1A1A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          color: Colors.white,
        ),
      ),
      home: const BarcodeHomePage(),
    );
  }
}
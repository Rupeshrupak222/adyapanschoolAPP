import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdyapanTheme {
  // Primary Colors (Light Mode Sky & Blue Gradients)
  static const Color bgDark = Color(0xFFF8FAFC);        // Slate 50
  static const Color bgDarker = Color(0xFFFFFFFF);      // Pure White
  static const Color bgLightDark = Color(0xFFF1F5F9);  // Slate 100

  static const Color textMain = Color(0xFF0F172A);      // Slate 900
  static const Color textSub = Color(0xFF475569);       // Slate 600
  static const Color textMuted = Color(0xFF64748B);     // Slate 500

  // Gamification Accent Colors
  static const Color blueAccent = Color(0xFF2563EB);    // Royal Blue 600
  static const Color cyan = Color(0xFF0284C7);          // Sky 600
  static const Color purple = Color(0xFF4F46E5);        // Indigo 600
  static const Color pink = Color(0xFFDB2777);          // Pink 600
  static const Color orange = Color(0xFFEA580C);        // Orange 600
  static const Color green = Color(0xFF16A34A);         // Green 600

  // Glassmorphic Shadows & Borders
  static const Color glassBorder = Color(0x1F2563EB);   // Soft blue border tint (12% opacity)
  static const Color glassBg = Color(0xC0FFFFFF);       // 75% White
  static const Color glassHover = Color(0x0F2563EB);    // 6% blue accent
  
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: blueAccent.withOpacity(0.08),
      blurRadius: 30,
      offset: const Offset(0, 10),
      spreadRadius: -5,
    ),
    const BoxShadow(
      color: Color(0x08000000),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [blueAccent, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient focusGradient = LinearGradient(
    colors: [pink, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [orange, Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Fonts
  static TextStyle fredoka({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = textMain,
  }) {
    if (Platform.isIOS) {
      return TextStyle(
        fontFamily: '.SF Pro Text',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
    return GoogleFonts.fredoka(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle outfit({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = textMain,
    double height = 1.2,
  }) {
    if (Platform.isIOS) {
      return TextStyle(
        fontFamily: '.SF Pro Text',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );
    }
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // Common glassmorphic container decoration
  static BoxDecoration glassCardDecoration({Color? customBg, BorderRadius? customRadius}) {
    return BoxDecoration(
      color: customBg ?? glassBg,
      border: Border.all(color: glassBorder, width: 1.5),
      borderRadius: customRadius ?? BorderRadius.circular(24),
      boxShadow: cardShadow,
    );
  }
}

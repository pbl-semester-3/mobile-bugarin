import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0B0D);
  static const Color surface = Color(0xFF17171B);
  static const Color teal = Color(0xFF2DE1C2);
  static const Color purple = Color(0xFFA855F7);
  static const Color textPrimary = Colors.white;
  static const Color textMuted = Color(0xFFA0A0AB);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, purple],
  );
}
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  AppShadows._();

  // Soft shadow (matching shadow-soft from Tailwind)
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.shadowColorLight,
          offset: const Offset(0, 1),
          blurRadius: 3,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: AppColors.shadowColorLight,
          offset: const Offset(0, 1),
          blurRadius: 2,
          spreadRadius: -1,
        ),
      ];

  // Medium shadow (matching shadow-medium from Tailwind)
  static List<BoxShadow> get medium => [
        BoxShadow(
          color: AppColors.shadowColor,
          offset: const Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: AppColors.shadowColorLight,
          offset: const Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -2,
        ),
      ];

  // Large shadow
  static List<BoxShadow> get large => [
        BoxShadow(
          color: AppColors.shadowColor,
          offset: const Offset(0, 10),
          blurRadius: 15,
          spreadRadius: -3,
        ),
        BoxShadow(
          color: AppColors.shadowColorLight,
          offset: const Offset(0, 4),
          blurRadius: 6,
          spreadRadius: -4,
        ),
      ];

  // Extra large shadow
  static List<BoxShadow> get extraLarge => [
        BoxShadow(
          color: AppColors.shadowColorDark,
          offset: const Offset(0, 20),
          blurRadius: 25,
          spreadRadius: -5,
        ),
        BoxShadow(
          color: AppColors.shadowColor,
          offset: const Offset(0, 8),
          blurRadius: 10,
          spreadRadius: -6,
        ),
      ];

  // Card shadow
  static List<BoxShadow> get card => soft;

  // Button shadow
  static List<BoxShadow> get button => soft;

  // Elevated button hover shadow
  static List<BoxShadow> get buttonHover => medium;

  // Dialog shadow
  static List<BoxShadow> get dialog => large;

  // Modal shadow
  static List<BoxShadow> get modal => extraLarge;

  // No shadow
  static List<BoxShadow> get none => [];
} 
// lib/widgets/button_gradient.dart

import 'package:flutter/material.dart';

class ButtonGradient {
  static const Color start = Color(0xFF8194E7);
  static const Color end = Color(0xFF87CCD2);
  static const Color text = Color(0xFF0C3154);

  static BoxDecoration decoration({double radius = 20}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [start, end],
      ),
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

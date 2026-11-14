import 'package:flutter/material.dart';

// share the same earthy category colors across charts and expense cards
abstract final class CategoryStyle {
  static Color color(String category) => switch (category) {
    'Food' => const Color(0xFF35634F),
    'Shopping' => const Color(0xFFAD624A),
    'Transportation' => const Color(0xFF50758B),
    'Entertainment' => const Color(0xFF86648C),
    'Travel' => const Color(0xFF74813C),
    'Bills' => const Color(0xFF9B762D),
    _ => const Color(0xFF727F79),
  };

  static Color tint(String category, {double strength = 0.08}) =>
      Color.lerp(Colors.white, color(category), strength)!;
}

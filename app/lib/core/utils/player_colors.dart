import 'package:flutter/material.dart';

const List<Color> playerAvatarColors = [
  Color(0xFF2196F3), // blue
  Color(0xFFE53935), // red
  Color(0xFF43A047), // green
  Color(0xFFFF8F00), // amber
  Color(0xFF8E24AA), // purple
  Color(0xFF00ACC1), // cyan
  Color(0xFFE91E63), // pink
  Color(0xFF6D4C41), // brown
];

Color playerAvatarColorForIndex(int index) {
  return playerAvatarColors[index % playerAvatarColors.length];
}

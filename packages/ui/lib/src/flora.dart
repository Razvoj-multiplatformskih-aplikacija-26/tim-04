import 'package:flutter/painting.dart';

/// The "Spring Whispers" palette. Only the theme uses these; widgets read colors from `Theme.of(context)`.
abstract final class Flora {
  static const leaf = Color(0xFF60992D);
  static const sage = Color(0xFF8CAE68);
  static const rose = Color(0xFFD991BA);
  static const blossom = Color(0xFFEBB9DF);
  static const blush = Color(0xFFF5D5ED);

  /// Darker leaf for buttons and links: white text on [leaf] has too little contrast.
  static const leafDeep = Color(0xFF44701C);
  static const petal = Color(0xFFFFFAFD);
  static const ink = Color(0xFF2A2230);
}

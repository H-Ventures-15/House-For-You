import 'package:flutter/material.dart';

/// Palette restreinte du design system (voir architecture-mvp.md, section 8).
/// Toutes les couleurs de l'app doivent passer par cette classe — jamais de
/// `Color(0x...)` en dur dans un écran.
abstract final class AppColors {
  // Primaire / marque
  static const Color primary = Color(0xFF1F6F5C);
  static const Color primaryLight = Color(0xFF4C9C87);
  static const Color primaryDark = Color(0xFF13473A);

  // Secondaire / accent
  static const Color accent = Color(0xFFE8A33D);

  // Neutres
  static const Color background = Color(0xFFFAFAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE3E1DC);
  static const Color textPrimary = Color(0xFF1A1A18);
  static const Color textSecondary = Color(0xFF6B6A64);
  static const Color textDisabled = Color(0xFFAFAEA8);

  // Sémantiques
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFE8A33D);

  // Overlays (ex. dégradé bas de carte plein écran dans le feed)
  static const Color overlayScrim = Color(0xCC000000);
}

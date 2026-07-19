import 'package:flutter/material.dart';
import '../../core/widgets/placeholder_screen.dart';
import '../../l10n/app_localizations.dart';

/// Onglet Favoris — écran temporaire. Les états invité/connecté avec la
/// liste des biens sauvegardés (étape 6 du plan) remplaceront ce placeholder.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlaceholderScreen(
      icon: Icons.favorite_rounded,
      title: l10n.navFavorites,
      subtitle: l10n.favoritesComingSoon,
    );
  }
}

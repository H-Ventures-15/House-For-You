import 'package:flutter/material.dart';
import '../../core/widgets/placeholder_screen.dart';
import '../../l10n/app_localizations.dart';

/// Onglet Rechercher — écran temporaire. La recherche guidée par étapes
/// (étape 3 du plan) remplacera ce placeholder.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlaceholderScreen(
      icon: Icons.search_rounded,
      title: l10n.navSearch,
      subtitle: l10n.searchComingSoon,
    );
  }
}

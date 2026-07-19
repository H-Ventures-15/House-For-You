import 'package:flutter/material.dart';
import '../../core/widgets/placeholder_screen.dart';
import '../../l10n/app_localizations.dart';

/// Onglet Découvrir — écran temporaire. Le feed vertical plein écran
/// (étape 2 du plan) remplacera ce placeholder.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlaceholderScreen(
      icon: Icons.explore_rounded,
      title: l10n.navDiscover,
      subtitle: l10n.discoverComingSoon,
    );
  }
}

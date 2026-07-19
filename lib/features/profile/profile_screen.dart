import 'package:flutter/material.dart';
import '../../core/widgets/placeholder_screen.dart';
import '../../l10n/app_localizations.dart';

/// Onglet Profil — écran temporaire. Les états invité/connecté avec
/// consultation/édition (étape 8 du plan) remplaceront ce placeholder.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlaceholderScreen(
      icon: Icons.person_rounded,
      title: l10n.navProfile,
      subtitle: l10n.profileComingSoon,
    );
  }
}

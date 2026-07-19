import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État d'authentification minimal — l'authentification réelle (Supabase
/// Auth) arrive à l'étape 5 du plan. Pour l'étape 0, ce provider simule un
/// visiteur non connecté afin que les écrans "invité vs connecté" (Favoris,
/// Profil) puissent déjà être développés contre une interface stable.
///
/// Les actions protégées (favori, contact, visite, alerte) doivent lire ce
/// provider avant de s'exécuter plutôt que de bloquer l'app au lancement —
/// voir architecture-mvp.md, section 1 et 7.
final authStateProvider = StateProvider<bool>((ref) => false);

bool isAuthenticated(WidgetRef ref) => ref.watch(authStateProvider);

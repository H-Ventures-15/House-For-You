import 'package:flutter/material.dart';
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

/// Porte d'entrée pour toute action protégée (favori, contact, visite,
/// alerte). L'écran de connexion/inscription modal réel arrive à l'étape 5 —
/// en attendant, un invité qui déclenche une action protégée voit un message
/// explicite plutôt qu'un blocage silencieux ou un écran de connexion créé
/// prématurément.
bool requireAuth(
  BuildContext context,
  WidgetRef ref, {
  required String message,
}) {
  if (isAuthenticated(ref)) return true;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
  return false;
}

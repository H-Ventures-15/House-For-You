import 'package:flutter/material.dart';

/// Recherche sauvegardée — prépare l'UX de la barre flottante et du panneau
/// "recherches enregistrées" du feed Découvrir. Purement local/mock à cette
/// étape : la recherche guidée réelle (étape 3) et sa persistance (étape 10,
/// bascule Supabase) brancheront ce modèle sans changement côté UI.
class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
}

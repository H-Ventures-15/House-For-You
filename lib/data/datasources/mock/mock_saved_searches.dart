import 'package:flutter/material.dart';
import '../../models/saved_search.dart';

/// Données fictives pour le panneau "recherches enregistrées" — prépare
/// l'UX avant la recherche guidée réelle (étape 3) et sa persistance
/// (étape 10, bascule Supabase).
final List<SavedSearch> mockSavedSearches = [
  const SavedSearch(
    id: 'search-1',
    label: 'Maison à Mons',
    subtitle: 'Vente · Jusqu\'à 350 000 €',
    icon: Icons.house_rounded,
  ),
  const SavedSearch(
    id: 'search-2',
    label: 'Appartement à Bruxelles',
    subtitle: 'Vente · 2 chambres min.',
    icon: Icons.apartment_rounded,
  ),
  const SavedSearch(
    id: 'search-3',
    label: 'Villa à Namur',
    subtitle: 'Vente · Avec piscine',
    icon: Icons.villa_rounded,
  ),
  const SavedSearch(
    id: 'search-4',
    label: 'Studio à Liège',
    subtitle: 'Location · Jusqu\'à 700 €/mois',
    icon: Icons.meeting_room_rounded,
  ),
];

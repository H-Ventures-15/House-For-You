import 'package:flutter/material.dart';

import 'property.dart';

/// Badges éditoriaux/commerciaux d'un bien — purement dérivés de [Property],
/// jamais stockés séparément (voir `propertyBadges`). Mock à cette étape,
/// mais le modèle (champs `isExclusive`/`isFeatured`/`hasVirtualTour`/
/// `previousPrice` sur [Property]) est déjà celui qui alimentera la vraie
/// donnée à la bascule Supabase (étape 10) — voir DATABASE_PLAN.md.
enum PropertyBadge {
  exclusive,
  featured,
  priceReduced,
  virtualTour,
  newListing
}

/// Un bien publié depuis moins de 14 jours est considéré "Nouveau" — seuil
/// choisi pour rester cohérent avec la fraîcheur perçue d'un feed immobilier
/// (ni trop large pour rester informatif, ni trop court pour ne jamais
/// s'afficher).
const Duration kNewListingWindow = Duration(days: 14);

/// Calcule les badges applicables à un bien, triés par ordre de priorité
/// éditoriale (une exclusivité prime sur une simple nouveauté, par exemple).
/// Le composant d'affichage se charge de n'en montrer que 1 ou 2 au maximum
/// (voir UX_RULES.md) — cette fonction retourne la liste complète triée.
List<PropertyBadge> propertyBadges(Property property, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final badges = <PropertyBadge>[];
  if (property.isExclusive) badges.add(PropertyBadge.exclusive);
  if (property.isFeatured) badges.add(PropertyBadge.featured);
  if (property.previousPrice != null &&
      property.previousPrice! > property.price) {
    badges.add(PropertyBadge.priceReduced);
  }
  if (property.hasVirtualTour) badges.add(PropertyBadge.virtualTour);
  final publishedAt = property.publishedAt;
  if (publishedAt != null &&
      reference.difference(publishedAt) <= kNewListingWindow) {
    badges.add(PropertyBadge.newListing);
  }
  return badges;
}

String propertyBadgeLabel(PropertyBadge badge) {
  return switch (badge) {
    PropertyBadge.exclusive => 'Exclusivité',
    PropertyBadge.featured => 'Coup de cœur',
    PropertyBadge.priceReduced => 'Prix réduit',
    PropertyBadge.virtualTour => 'Visite virtuelle',
    PropertyBadge.newListing => 'Nouveau',
  };
}

IconData propertyBadgeIcon(PropertyBadge badge) {
  return switch (badge) {
    PropertyBadge.exclusive => Icons.workspace_premium_rounded,
    PropertyBadge.featured => Icons.favorite_rounded,
    PropertyBadge.priceReduced => Icons.trending_down_rounded,
    PropertyBadge.virtualTour => Icons.threed_rotation_rounded,
    PropertyBadge.newListing => Icons.fiber_new_rounded,
  };
}

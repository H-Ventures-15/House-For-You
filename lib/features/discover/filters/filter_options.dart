import 'package:flutter/material.dart';

import '../../../core/widgets/property_card.dart' show propertyTypeLabel;
import '../../../data/models/property.dart';
import '../../../data/models/search_filters.dart';

/// Métadonnées d'affichage (libellé + icône) pour les grilles de la feuille
/// de filtres. Séparées du modèle [SearchFilters] lui-même, qui ne connaît
/// que des valeurs — jamais de widget dans `data/`.

class TransactionOption {
  const TransactionOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final TransactionType? value;
}

/// `value: null` pour "Projet neuf" — traité comme une vente au MVP mock
/// (aucune colonne dédiée dans `Property`), voir `SearchFilters.matches`.
const transactionOptions = [
  TransactionOption(
    label: 'Acheter',
    subtitle: 'Biens à la vente',
    icon: Icons.key_rounded,
    value: TransactionType.sale,
  ),
  TransactionOption(
    label: 'Louer',
    subtitle: 'Biens en location',
    icon: Icons.apartment_rounded,
    value: TransactionType.rent,
  ),
  TransactionOption(
    label: 'Projet neuf',
    subtitle: 'Constructions neuves',
    icon: Icons.construction_rounded,
    value: TransactionType.sale,
  ),
];

class PropertyTypeOption {
  const PropertyTypeOption({
    required this.label,
    required this.icon,
    required this.type,
  });

  final String label;
  final IconData icon;

  /// Catégorie sous-jacente pour le comptage simulé — plusieurs libellés
  /// (Villa, Projet neuf, Commerce...) partagent volontairement la même
  /// valeur, faute de granularité plus fine dans les données mock.
  final PropertyType type;
}

const propertyTypeOptions = [
  PropertyTypeOption(
    label: 'Maison',
    icon: Icons.house_rounded,
    type: PropertyType.house,
  ),
  PropertyTypeOption(
    label: 'Appartement',
    icon: Icons.apartment_rounded,
    type: PropertyType.apartment,
  ),
  PropertyTypeOption(
    label: 'Villa',
    icon: Icons.villa_rounded,
    type: PropertyType.house,
  ),
  PropertyTypeOption(
    label: 'Terrain',
    icon: Icons.terrain_rounded,
    type: PropertyType.land,
  ),
  PropertyTypeOption(
    label: 'Projet neuf',
    icon: Icons.foundation_rounded,
    type: PropertyType.other,
  ),
  PropertyTypeOption(
    label: 'Immeuble de rapport',
    icon: Icons.location_city_rounded,
    type: PropertyType.other,
  ),
  PropertyTypeOption(
    label: 'Commerce',
    icon: Icons.storefront_rounded,
    type: PropertyType.other,
  ),
  PropertyTypeOption(
    label: 'Entrepôt',
    icon: Icons.warehouse_rounded,
    type: PropertyType.other,
  ),
  PropertyTypeOption(
    label: 'Garage',
    icon: Icons.garage_rounded,
    type: PropertyType.other,
  ),
];

class CharacteristicOption {
  const CharacteristicOption({
    required this.label,
    required this.icon,
    required this.key,
  });

  final String label;
  final IconData icon;

  /// Clé comparée à `Property.features` (ou aux colonnes structurées pour
  /// garden/garage/terrace) — voir `SearchFilters._hasCharacteristic`.
  final String key;
}

const characteristicOptions = [
  CharacteristicOption(
    label: 'Jardin',
    icon: Icons.grass_rounded,
    key: 'garden',
  ),
  CharacteristicOption(
    label: 'Terrasse',
    icon: Icons.deck_rounded,
    key: 'terrace',
  ),
  CharacteristicOption(
    label: 'Piscine',
    icon: Icons.pool_rounded,
    key: 'piscine',
  ),
  CharacteristicOption(
    label: 'Garage',
    icon: Icons.garage_rounded,
    key: 'garage',
  ),
  CharacteristicOption(
    label: 'Parking',
    icon: Icons.local_parking_rounded,
    key: 'parking',
  ),
  CharacteristicOption(label: 'Cave', icon: Icons.stairs_rounded, key: 'cave'),
  CharacteristicOption(
    label: 'Bureau',
    icon: Icons.work_outline_rounded,
    key: 'bureau',
  ),
  CharacteristicOption(
    label: 'Dressing',
    icon: Icons.checkroom_rounded,
    key: 'dressing',
  ),
  CharacteristicOption(
    label: 'Cheminée',
    icon: Icons.fireplace_rounded,
    key: 'cheminee',
  ),
  CharacteristicOption(
    label: 'Ascenseur',
    icon: Icons.elevator_rounded,
    key: 'ascenseur',
  ),
  CharacteristicOption(
    label: 'Accessible PMR',
    icon: Icons.accessible_rounded,
    key: 'pmr',
  ),
  CharacteristicOption(
    label: 'Cuisine équipée',
    icon: Icons.kitchen_rounded,
    key: 'cuisine_equipee',
  ),
  CharacteristicOption(
    label: 'Climatisation',
    icon: Icons.ac_unit_rounded,
    key: 'climatisation',
  ),
  CharacteristicOption(
    label: 'Pompe à chaleur',
    icon: Icons.heat_pump_rounded,
    key: 'pompe_a_chaleur',
  ),
  CharacteristicOption(
    label: 'Panneaux photovoltaïques',
    icon: Icons.solar_power_rounded,
    key: 'panneaux_photovoltaiques',
  ),
  CharacteristicOption(
    label: 'Borne électrique',
    icon: Icons.ev_station_rounded,
    key: 'borne_electrique',
  ),
  CharacteristicOption(
    label: 'Vue dégagée',
    icon: Icons.landscape_rounded,
    key: 'vue_degagee',
  ),
];

class ConditionOption {
  const ConditionOption({required this.label, required this.value});

  final String label;
  final PropertyCondition value;
}

const conditionOptions = [
  ConditionOption(label: 'Neuf', value: PropertyCondition.newBuild),
  ConditionOption(label: 'Excellent', value: PropertyCondition.excellent),
  ConditionOption(label: 'Bon', value: PropertyCondition.good),
  ConditionOption(label: 'À rénover', value: PropertyCondition.toRenovate),
  ConditionOption(label: 'Gros œuvre', value: PropertyCondition.shell),
];

class PublicationOption {
  const PublicationOption({required this.label, required this.value});

  final String label;
  final PublicationRecency value;
}

const publicationOptions = [
  PublicationOption(label: 'Aujourd\'hui', value: PublicationRecency.today),
  PublicationOption(label: '7 jours', value: PublicationRecency.sevenDays),
  PublicationOption(label: '30 jours', value: PublicationRecency.thirtyDays),
  PublicationOption(label: 'Toutes', value: PublicationRecency.all),
];

class SortOptionEntry {
  const SortOptionEntry({required this.label, required this.value});

  final String label;
  final SortOption value;
}

const sortOptions = [
  SortOptionEntry(label: 'Pertinence', value: SortOption.relevance),
  SortOptionEntry(label: 'Nouveautés', value: SortOption.newest),
  SortOptionEntry(label: 'Prix croissant', value: SortOption.priceAsc),
  SortOptionEntry(label: 'Prix décroissant', value: SortOption.priceDesc),
  SortOptionEntry(label: 'Surface', value: SortOption.surface),
  SortOptionEntry(label: 'Prix/m²', value: SortOption.pricePerSqm),
];

class RadiusOption {
  const RadiusOption({required this.label, required this.km});

  final String label;

  /// `null` = "Toute la Belgique" (pas de contrainte de rayon).
  final double? km;
}

const radiusOptions = [
  RadiusOption(label: '5 km', km: 5),
  RadiusOption(label: '10 km', km: 10),
  RadiusOption(label: '20 km', km: 20),
  RadiusOption(label: '50 km', km: 50),
  RadiusOption(label: 'Toute la Belgique', km: null),
];

class AmbianceOption {
  const AmbianceOption({
    required this.emoji,
    required this.label,
    required this.key,
  });

  final String emoji;
  final String label;
  final String key;
}

/// Section "bonus" différenciante — explorer par ressenti plutôt que par
/// critère technique. Purement déclaratif au MVP (aucune donnée mock ne s'y
/// prête encore), n'influence pas le nombre de résultats simulé.
const ambianceOptions = [
  AmbianceOption(emoji: '🌳', label: 'Calme', key: 'calme'),
  AmbianceOption(emoji: '☀️', label: 'Très lumineux', key: 'lumineux'),
  AmbianceOption(emoji: '👨‍👩‍👧', label: 'Familial', key: 'familial'),
  AmbianceOption(emoji: '🏙', label: 'Centre-ville', key: 'centre_ville'),
  AmbianceOption(emoji: '🌲', label: 'Proche nature', key: 'nature'),
  AmbianceOption(emoji: '💼', label: 'Télétravail', key: 'teletravail'),
  AmbianceOption(emoji: '🍷', label: 'Haut de gamme', key: 'haut_de_gamme'),
  AmbianceOption(emoji: '🎓', label: 'Étudiant', key: 'etudiant'),
  AmbianceOption(
    emoji: '🚉',
    label: 'Proche transports',
    key: 'transports',
  ),
];

const energyScoreOptions = ['A+', 'A', 'B', 'C', 'D', 'E', 'F', 'G'];

/// Couleur conventionnelle de l'échiquier PEB (vert → rouge).
const Map<String, Color> energyScoreColors = {
  'A+': Color(0xFF0E7C42),
  'A': Color(0xFF2E9E4B),
  'B': Color(0xFF7AB648),
  'C': Color(0xFFC7D046),
  'D': Color(0xFFF0C93E),
  'E': Color(0xFFEF9B3D),
  'F': Color(0xFFE96A2C),
  'G': Color(0xFFD8342A),
};

const bedroomQuickOptions = [1, 2, 3, 4, 5];
const bathroomQuickOptions = [1, 2, 3, 4, 5];

/// Suggestions statiques pour la recherche de localisation — au MVP mock,
/// aucun service de géocodage n'est branché (voir architecture-mvp.md,
/// section 1). Couvre les localités déjà présentes dans les biens mock plus
/// quelques grandes villes belges pour une démonstration crédible des
/// suggestions instantanées.
/// Résumé compact affiché dans la barre flottante — reflète en direct
/// l'état de `searchFiltersControllerProvider`.
String summarizeFilters(SearchFilters filters) {
  if (filters.isEmpty) return 'Toute la Belgique · Tous types · Budget libre';

  final parts = <String>[];

  if (filters.transactionType != null) {
    parts.add(
      filters.transactionType == TransactionType.rent ? 'Louer' : 'Acheter',
    );
  }

  parts.add(
    (filters.city?.isNotEmpty ?? false) ? filters.city! : 'Toute la Belgique',
  );

  if (filters.propertyTypes.isEmpty) {
    parts.add('Tous types');
  } else if (filters.propertyTypes.length == 1) {
    final match = propertyTypeOptions.firstWhere(
      (o) => o.type == filters.propertyTypes.first,
      orElse: () => propertyTypeOptions.first,
    );
    parts.add(match.label);
  } else {
    parts.add('${filters.propertyTypes.length} types');
  }

  if (filters.budgetMin == null && filters.budgetMax == null) {
    parts.add('Budget libre');
  } else if (filters.budgetMax != null) {
    parts.add('Jusqu\'à ${_formatBudget(filters.budgetMax!)}');
  } else {
    parts.add('Dès ${_formatBudget(filters.budgetMin!)}');
  }

  return parts.join(' · ');
}

String _formatBudget(num value) {
  if (value >= 1000) return '${(value / 1000).round()}k €';
  return '${value.round()} €';
}

// --- Recherches sauvegardées : libellé/sous-titre/icône dérivés ---------
//
// `SavedSearch` ne stocke que des `SearchFilters` (voir
// `data/models/saved_search.dart`) — label par défaut, sous-titre et icône
// affichés dans les aperçus/listes se calculent à la volée pour ne jamais
// dupliquer ce que les critères disent déjà.

/// Nom par défaut proposé lors de l'enregistrement d'une recherche — ex.
/// "Maison à Mons", "Appartement à Bruxelles". Toujours modifiable par
/// l'utilisateur avant confirmation (voir `filters_sheet.dart`).
String defaultSavedSearchName(SearchFilters filters) {
  final typeLabel = filters.propertyTypes.isEmpty
      ? 'Recherche'
      : propertyTypeLabel(filters.propertyTypes.first);
  final place = (filters.city?.isNotEmpty ?? false)
      ? filters.city!
      : (filters.province ?? 'en Belgique');
  return place.startsWith('en ') ? '$typeLabel $place' : '$typeLabel à $place';
}

/// Résumé court affiché sous le libellé d'une recherche sauvegardée — ex.
/// "Vente · Jusqu'à 350k €".
String savedSearchSubtitle(SearchFilters filters) {
  final parts = <String>[];
  if (filters.transactionType != null) {
    parts.add(
      filters.transactionType == TransactionType.rent ? 'Location' : 'Vente',
    );
  }
  if (filters.budgetMax != null) {
    final suffix =
        filters.transactionType == TransactionType.rent ? '/mois' : '';
    parts.add('Jusqu\'à ${_formatBudget(filters.budgetMax!)}$suffix');
  } else if (filters.minBedrooms != null) {
    parts.add('${filters.minBedrooms}+ chambres');
  } else if (filters.characteristics.isNotEmpty) {
    parts.add('${filters.characteristics.length} critère(s)');
  }
  if (parts.isEmpty) return 'Tous les critères';
  return parts.join(' · ');
}

/// Icône représentative — celle du premier type de bien sélectionné, sinon
/// une icône de recherche générique.
IconData savedSearchIcon(SearchFilters filters) {
  if (filters.propertyTypes.isEmpty) return Icons.search_rounded;
  final match = propertyTypeOptions.firstWhere(
    (o) => filters.propertyTypes.contains(o.type),
    orElse: () => propertyTypeOptions.first,
  );
  return match.icon;
}

const locationSuggestions = [
  'Bruxelles',
  'Ixelles',
  'Saint-Gilles',
  'Namur',
  'Jambes',
  'Liège',
  'Grivegnée',
  'Eghezée',
  'Braine-l\'Alleud',
  'Mons',
  'Charleroi',
  'Tournai',
  'Wavre',
  'Nivelles',
  'Verviers',
  'Arlon',
  'Bruxelles-Capitale',
  'Brabant wallon',
  'Province de Namur',
  'Province de Liège',
  'Province de Hainaut',
  'Wallonie',
];

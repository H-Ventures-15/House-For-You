import 'property.dart';

/// Grille de lecture pour "État du bien" — aucun équivalent structuré dans
/// [Property] au MVP (mock), sert surtout à préparer l'UX de la feuille de
/// filtres avant l'étape 10 (bascule Supabase).
enum PropertyCondition { newBuild, excellent, good, toRenovate, shell }

enum PublicationRecency { today, sevenDays, thirtyDays, all }

enum SortOption { relevance, newest, priceAsc, priceDesc, surface, pricePerSqm }

/// Objet non persisté — construit au fil des étapes de la recherche guidée
/// (étape 3) et, dès l'étape 2, par la feuille de filtres accessible depuis
/// la barre flottante du feed Découvrir. `matches()` ne s'applique qu'aux
/// critères qui ont un équivalent dans les données mock ; l'état du bien et
/// les ambiances de vie n'ont pas de colonne structurée dans [Property] au
/// MVP et servent avant tout à préparer l'expérience (voir
/// architecture-mvp.md, section 1 — mock avant Supabase).
class SearchFilters {
  const SearchFilters({
    this.transactionType,
    this.propertyTypes = const {},
    this.city,
    this.province,
    this.radiusKm,
    this.budgetMin,
    this.budgetMax,
    this.minBedrooms,
    this.minBathrooms,
    this.minSurface,
    this.maxSurface,
    this.minLandSurface,
    this.maxLandSurface,
    this.energyScores = const {},
    this.characteristics = const {},
    this.condition,
    this.publicationRecency,
    this.sortOption = SortOption.relevance,
    this.ambiances = const {},
  });

  final TransactionType? transactionType;
  final Set<PropertyType> propertyTypes;
  final String? city;
  final String? province;
  final double? radiusKm;
  final num? budgetMin;
  final num? budgetMax;
  final int? minBedrooms;
  final int? minBathrooms;
  final num? minSurface;
  final num? maxSurface;
  final num? minLandSurface;
  final num? maxLandSurface;
  final Set<String> energyScores;

  /// Clés libres — `garden`/`garage`/`terrace` correspondent aux colonnes
  /// structurées de [Property], les autres (piscine, cave, bureau...) sont
  /// comparées à [Property.features] (voir `_hasCharacteristic`).
  final Set<String> characteristics;
  final PropertyCondition? condition;
  final PublicationRecency? publicationRecency;
  final SortOption sortOption;
  final Set<String> ambiances;

  bool get isEmpty =>
      transactionType == null &&
      propertyTypes.isEmpty &&
      (city == null || city!.isEmpty) &&
      province == null &&
      radiusKm == null &&
      budgetMin == null &&
      budgetMax == null &&
      minBedrooms == null &&
      minBathrooms == null &&
      minSurface == null &&
      maxSurface == null &&
      minLandSurface == null &&
      maxLandSurface == null &&
      energyScores.isEmpty &&
      characteristics.isEmpty &&
      condition == null &&
      publicationRecency == null &&
      ambiances.isEmpty;

  /// Nombre de groupes de critères actifs — alimente le badge du bouton
  /// Filtres.
  int get activeFilterCount {
    var count = 0;
    if (transactionType != null) count++;
    if (propertyTypes.isNotEmpty) count++;
    if ((city != null && city!.isNotEmpty) ||
        province != null ||
        radiusKm != null) {
      count++;
    }
    if (budgetMin != null || budgetMax != null) count++;
    if (minBedrooms != null) count++;
    if (minBathrooms != null) count++;
    if (minSurface != null || maxSurface != null) count++;
    if (minLandSurface != null || maxLandSurface != null) count++;
    if (energyScores.isNotEmpty) count++;
    if (characteristics.isNotEmpty) count++;
    if (condition != null) count++;
    if (publicationRecency != null) count++;
    if (ambiances.isNotEmpty) count++;
    return count;
  }

  SearchFilters copyWith({
    TransactionType? Function()? transactionType,
    Set<PropertyType>? propertyTypes,
    String? Function()? city,
    String? Function()? province,
    double? Function()? radiusKm,
    num? Function()? budgetMin,
    num? Function()? budgetMax,
    int? Function()? minBedrooms,
    int? Function()? minBathrooms,
    num? Function()? minSurface,
    num? Function()? maxSurface,
    num? Function()? minLandSurface,
    num? Function()? maxLandSurface,
    Set<String>? energyScores,
    Set<String>? characteristics,
    PropertyCondition? Function()? condition,
    PublicationRecency? Function()? publicationRecency,
    SortOption? sortOption,
    Set<String>? ambiances,
  }) {
    return SearchFilters(
      transactionType:
          transactionType != null ? transactionType() : this.transactionType,
      propertyTypes: propertyTypes ?? this.propertyTypes,
      city: city != null ? city() : this.city,
      province: province != null ? province() : this.province,
      radiusKm: radiusKm != null ? radiusKm() : this.radiusKm,
      budgetMin: budgetMin != null ? budgetMin() : this.budgetMin,
      budgetMax: budgetMax != null ? budgetMax() : this.budgetMax,
      minBedrooms: minBedrooms != null ? minBedrooms() : this.minBedrooms,
      minBathrooms: minBathrooms != null ? minBathrooms() : this.minBathrooms,
      minSurface: minSurface != null ? minSurface() : this.minSurface,
      maxSurface: maxSurface != null ? maxSurface() : this.maxSurface,
      minLandSurface:
          minLandSurface != null ? minLandSurface() : this.minLandSurface,
      maxLandSurface:
          maxLandSurface != null ? maxLandSurface() : this.maxLandSurface,
      energyScores: energyScores ?? this.energyScores,
      characteristics: characteristics ?? this.characteristics,
      condition: condition != null ? condition() : this.condition,
      publicationRecency: publicationRecency != null
          ? publicationRecency()
          : this.publicationRecency,
      sortOption: sortOption ?? this.sortOption,
      ambiances: ambiances ?? this.ambiances,
    );
  }

  bool matches(Property property) {
    if (transactionType != null &&
        property.transactionType != transactionType) {
      return false;
    }
    if (propertyTypes.isNotEmpty &&
        !propertyTypes.contains(property.propertyType)) {
      return false;
    }
    if (city != null && city!.isNotEmpty) {
      final query = city!.toLowerCase();
      final matchesCity = property.city.toLowerCase().contains(query);
      final matchesPostal = property.postalCode.contains(query);
      final matchesProvince =
          property.province?.toLowerCase().contains(query) ?? false;
      if (!matchesCity && !matchesPostal && !matchesProvince) return false;
    }
    if (province != null && property.province != province) return false;
    if (budgetMin != null && property.price < budgetMin!) return false;
    if (budgetMax != null && property.price > budgetMax!) return false;
    if (minBedrooms != null && property.bedrooms < minBedrooms!) return false;
    if (minBathrooms != null && (property.bathrooms ?? 0) < minBathrooms!) {
      return false;
    }
    if (minSurface != null && property.surface < minSurface!) return false;
    if (maxSurface != null && property.surface > maxSurface!) return false;
    if (minLandSurface != null &&
        (property.landSurface ?? 0) < minLandSurface!) {
      return false;
    }
    if (maxLandSurface != null &&
        (property.landSurface ?? double.infinity) > maxLandSurface!) {
      return false;
    }
    if (energyScores.isNotEmpty &&
        (property.energyScore == null ||
            !energyScores.contains(property.energyScore))) {
      return false;
    }
    for (final key in characteristics) {
      if (!_hasCharacteristic(property, key)) return false;
    }
    if (publicationRecency != null && !_matchesRecency(property)) {
      return false;
    }
    return true;
  }

  bool _hasCharacteristic(Property property, String key) {
    switch (key) {
      case 'garden':
        return property.garden;
      case 'garage':
        return property.garage;
      case 'terrace':
        return property.terrace;
      default:
        return property.features.any(
          (f) => f.featureKey == key && f.featureValue.toLowerCase() != 'non',
        );
    }
  }

  bool _matchesRecency(Property property) {
    final reference = property.publishedAt ?? property.createdAt;
    final age = DateTime.now().difference(reference);
    return switch (publicationRecency!) {
      PublicationRecency.today => age.inHours < 24,
      PublicationRecency.sevenDays => age.inDays < 7,
      PublicationRecency.thirtyDays => age.inDays < 30,
      PublicationRecency.all => true,
    };
  }
}

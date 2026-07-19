import 'property.dart';

/// Objet non persisté — construit au fil des étapes de la recherche guidée
/// (transaction → type → localisation → budget → chambres → critères).
class SearchFilters {
  const SearchFilters({
    this.transactionType,
    this.propertyType,
    this.city,
    this.budgetMin,
    this.budgetMax,
    this.minBedrooms,
    this.requireGarden = false,
    this.requireGarage = false,
    this.requireTerrace = false,
  });

  final TransactionType? transactionType;
  final PropertyType? propertyType;
  final String? city;
  final num? budgetMin;
  final num? budgetMax;
  final int? minBedrooms;
  final bool requireGarden;
  final bool requireGarage;
  final bool requireTerrace;

  SearchFilters copyWith({
    TransactionType? transactionType,
    PropertyType? propertyType,
    String? city,
    num? budgetMin,
    num? budgetMax,
    int? minBedrooms,
    bool? requireGarden,
    bool? requireGarage,
    bool? requireTerrace,
  }) {
    return SearchFilters(
      transactionType: transactionType ?? this.transactionType,
      propertyType: propertyType ?? this.propertyType,
      city: city ?? this.city,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      requireGarden: requireGarden ?? this.requireGarden,
      requireGarage: requireGarage ?? this.requireGarage,
      requireTerrace: requireTerrace ?? this.requireTerrace,
    );
  }

  bool matches(Property property) {
    if (transactionType != null &&
        property.transactionType != transactionType) {
      return false;
    }
    if (propertyType != null && property.propertyType != propertyType) {
      return false;
    }
    if (city != null &&
        city!.isNotEmpty &&
        !property.city.toLowerCase().contains(city!.toLowerCase())) {
      return false;
    }
    if (budgetMin != null && property.price < budgetMin!) return false;
    if (budgetMax != null && property.price > budgetMax!) return false;
    if (minBedrooms != null && property.bedrooms < minBedrooms!) return false;
    if (requireGarden && !property.garden) return false;
    if (requireGarage && !property.garage) return false;
    if (requireTerrace && !property.terrace) return false;
    return true;
  }
}

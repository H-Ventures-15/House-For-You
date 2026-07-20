import 'search_filters.dart';

/// Recherche sauvegardée — porte de vrais [SearchFilters], rechargeables
/// tels quels dans `searchFiltersControllerProvider`. Le libellé et
/// l'icône affichés dans les listes/aperçus se dérivent des critères (voir
/// `defaultSavedSearchName`/`savedSearchSubtitle`/`savedSearchIcon` dans
/// `filter_options.dart`) plutôt que d'être stockés en double.
///
/// Purement local/mémoire à cette étape (voir `MockSavedSearchesDataSource`)
/// — la persistance réelle arrivera avec la table Supabase `saved_searches`
/// (étape 10, voir DATABASE_PLAN.md section 3.12).
class SavedSearch {
  const SavedSearch({
    required this.id,
    required this.label,
    required this.filters,
    required this.createdAt,
  });

  final String id;
  final String label;
  final SearchFilters filters;
  final DateTime createdAt;

  SavedSearch copyWith({String? label}) {
    return SavedSearch(
      id: id,
      label: label ?? this.label,
      filters: filters,
      createdAt: createdAt,
    );
  }
}

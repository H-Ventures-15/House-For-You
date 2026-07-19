import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_filters.dart';
import 'feed_providers.dart';

/// État des filtres de recherche pour la session en cours — purement local
/// (aucune persistance, aucune connexion Supabase à cette étape). Lu par la
/// barre flottante (résumé) et la feuille de filtres (édition), voir
/// `FloatingSearchBar` / `filters_sheet.dart`.
class SearchFiltersController extends StateNotifier<SearchFilters> {
  SearchFiltersController() : super(const SearchFilters());

  void update(SearchFilters Function(SearchFilters current) updater) {
    state = updater(state);
  }

  void reset() => state = const SearchFilters();
}

final searchFiltersControllerProvider =
    StateNotifierProvider<SearchFiltersController, SearchFilters>((ref) {
  return SearchFiltersController();
});

/// Nombre de biens mock correspondant aux filtres actifs — alimente le
/// bouton "Afficher X biens" de la feuille de filtres. Réel calcul sur les
/// données mock (pas un chiffre inventé), mais reste un nombre simulé au
/// sens où aucune requête Supabase n'est faite (voir architecture-mvp.md,
/// section 1).
final filteredPropertyCountProvider = Provider<int>((ref) {
  final filters = ref.watch(searchFiltersControllerProvider);
  final feed = ref.watch(feedPropertiesProvider).valueOrNull ?? const [];
  if (filters.isEmpty) return feed.length;
  return feed.where(filters.matches).length;
});

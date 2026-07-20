import '../../models/property.dart';
import '../../models/saved_search.dart';
import '../../models/search_filters.dart';
import '../../repositories/saved_searches_repository.dart';

/// Stockage en mémoire — un seul jeu de données, faute d'une vraie session
/// utilisateur à cette étape (`userId` ignoré, voir
/// `SavedSearchesRepository`). Remplacé par la table Supabase
/// `saved_searches` à l'étape 10.
///
/// Semée avec des critères réels (pas de simples libellés statiques comme
/// avant Sprint 2.4) : "Maison à Mons" ne correspond volontairement à aucun
/// bien mock (aucune localité "Mons" dans `mock_property_data.dart`) — sert
/// de démonstration prête à l'emploi de l'état "zéro résultat" (voir
/// UX_RULES.md section 17) quand elle est chargée.
class MockSavedSearchesDataSource implements SavedSearchesRepository {
  final List<SavedSearch> _searches = [
    SavedSearch(
      id: 'search-1',
      label: 'Maison à Mons',
      filters: const SearchFilters(
        transactionType: TransactionType.sale,
        propertyTypes: {PropertyType.house},
        city: 'Mons',
        budgetMax: 350000,
      ),
      createdAt: DateTime(2026, 7, 18),
    ),
    SavedSearch(
      id: 'search-2',
      label: 'Appartement à Bruxelles',
      filters: const SearchFilters(
        transactionType: TransactionType.sale,
        propertyTypes: {PropertyType.apartment},
        city: 'Bruxelles',
        minBedrooms: 2,
      ),
      createdAt: DateTime(2026, 7, 19),
    ),
    SavedSearch(
      id: 'search-3',
      label: 'Villa à Namur',
      filters: const SearchFilters(
        transactionType: TransactionType.sale,
        propertyTypes: {PropertyType.house},
        city: 'Namur',
      ),
      createdAt: DateTime(2026, 7, 19),
    ),
    SavedSearch(
      id: 'search-4',
      label: 'Studio à Liège',
      filters: const SearchFilters(
        transactionType: TransactionType.rent,
        propertyTypes: {PropertyType.apartment},
        city: 'Liège',
        budgetMax: 700,
      ),
      createdAt: DateTime(2026, 7, 20),
    ),
  ];

  @override
  Future<List<SavedSearch>> getAll(String userId) async {
    return List.unmodifiable(_searches);
  }

  @override
  Future<SavedSearch> save(
    String userId,
    String label,
    SearchFilters filters,
  ) async {
    final search = SavedSearch(
      id: 'search-${DateTime.now().microsecondsSinceEpoch}',
      label: label,
      filters: filters,
      createdAt: DateTime.now(),
    );
    _searches.insert(0, search);
    return search;
  }

  @override
  Future<void> rename(String userId, String searchId, String newLabel) async {
    final index = _searches.indexWhere((s) => s.id == searchId);
    if (index == -1) return;
    _searches[index] = _searches[index].copyWith(label: newLabel);
  }

  @override
  Future<void> remove(String userId, String searchId) async {
    _searches.removeWhere((s) => s.id == searchId);
  }
}

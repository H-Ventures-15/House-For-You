import '../models/saved_search.dart';
import '../models/search_filters.dart';

/// `userId` sur chaque méthode prépare la future policy RLS Supabase
/// (`saved_searches.user_id`, voir DATABASE_PLAN.md section 3.12/5) — le
/// mock actuel (`MockSavedSearchesDataSource`) l'ignore et opère sur un
/// unique jeu de données en mémoire, faute d'une vraie session utilisateur
/// à cette étape (voir DECISIONS.md ADR-016 : contrairement aux favoris,
/// les recherches sauvegardées ne passent volontairement pas par
/// `requireAuth()` à ce stade).
abstract class SavedSearchesRepository {
  Future<List<SavedSearch>> getAll(String userId);

  Future<SavedSearch> save(String userId, String label, SearchFilters filters);

  Future<void> rename(String userId, String searchId, String newLabel);

  Future<void> remove(String userId, String searchId);
}

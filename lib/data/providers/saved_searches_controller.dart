import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_search.dart';
import '../models/search_filters.dart';
import 'favorites_controller.dart' show mockSessionUserId;
import 'repository_providers.dart';

/// Recherches sauvegardées de la session en cours — purement locale/mémoire
/// à cette étape (voir `MockSavedSearchesDataSource`). Contrairement aux
/// favoris, ce contrôleur n'est **pas** protégé par `requireAuth()` : voir
/// DECISIONS.md ADR-016 pour la justification (UX_RULES.md section 14 ne
/// liste pas cette action parmi celles qui exigent une session, et aucun
/// écran de connexion réel n'existe encore pour la valider autrement).
class SavedSearchesController
    extends StateNotifier<AsyncValue<List<SavedSearch>>> {
  SavedSearchesController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final repository = _ref.read(savedSearchesRepositoryProvider);
    try {
      final searches = await repository.getAll(mockSessionUserId);
      state = AsyncValue.data(searches);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<SavedSearch> save(String label, SearchFilters filters) async {
    final repository = _ref.read(savedSearchesRepositoryProvider);
    final created = await repository.save(mockSessionUserId, label, filters);
    state = AsyncValue.data([created, ...?state.valueOrNull]);
    return created;
  }

  Future<void> rename(String searchId, String newLabel) async {
    final repository = _ref.read(savedSearchesRepositoryProvider);
    await repository.rename(mockSessionUserId, searchId, newLabel);
    state = AsyncValue.data([
      for (final search in state.valueOrNull ?? const <SavedSearch>[])
        if (search.id == searchId) search.copyWith(label: newLabel) else search,
    ]);
  }

  Future<void> remove(String searchId) async {
    final repository = _ref.read(savedSearchesRepositoryProvider);
    await repository.remove(mockSessionUserId, searchId);
    state = AsyncValue.data([
      for (final search in state.valueOrNull ?? const <SavedSearch>[])
        if (search.id != searchId) search,
    ]);
  }
}

final savedSearchesControllerProvider = StateNotifierProvider<
    SavedSearchesController, AsyncValue<List<SavedSearch>>>((ref) {
  return SavedSearchesController(ref);
});

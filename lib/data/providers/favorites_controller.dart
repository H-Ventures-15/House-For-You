import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/session_id.dart';
import '../models/property_event.dart';
import 'repository_providers.dart';

/// Utilisateur unique simulé tant que l'authentification réelle (étape 5)
/// n'est pas branchée — `requireAuth` garantit que ce contrôleur n'est
/// jamais sollicité pour un invité.
const mockSessionUserId = 'session-user';

/// Ids des biens favoris — accessibles sans compte (voir DECISIONS.md) et
/// persistés localement (`MockFavoritesDataSource`, `SharedPreferences`)
/// pour survivre à un redémarrage de l'app tant que la synchronisation
/// Supabase (étape 5/6) n'existe pas.
class FavoritesController extends StateNotifier<Set<String>> {
  FavoritesController(this._ref) : super(const {}) {
    _hydrate();
  }

  final Ref _ref;

  Future<void> _hydrate() async {
    final favorites = await _ref.read(favoritesRepositoryProvider).getFavorites(
          mockSessionUserId,
        );
    if (!mounted) return;
    state = favorites.map((p) => p.id).toSet();
  }

  Future<void> toggle(String propertyId) async {
    final repository = _ref.read(favoritesRepositoryProvider);
    final adding = !state.contains(propertyId);

    if (adding) {
      await repository.addFavorite(mockSessionUserId, propertyId);
      state = {...state, propertyId};
    } else {
      await repository.removeFavorite(mockSessionUserId, propertyId);
      state = {...state}..remove(propertyId);
    }

    await _ref.read(analyticsServiceProvider).track(
          PropertyEvent(
            propertyId: propertyId,
            userId: mockSessionUserId,
            sessionId: _ref.read(sessionIdProvider),
            eventType: adding
                ? PropertyEventType.favoriteAdd
                : PropertyEventType.favoriteRemove,
            createdAt: DateTime.now(),
          ),
        );
  }
}

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, Set<String>>((ref) {
  return FavoritesController(ref);
});

import '../../models/property.dart';
import '../../repositories/favorites_repository.dart';
import 'mock_property_data.dart';

/// Stockage en mémoire — au MVP réel, nécessite une session (voir
/// `AuthGuard`). Remplacé par la table Supabase `favorites` à l'étape 10.
class MockFavoritesDataSource implements FavoritesRepository {
  final Map<String, Set<String>> _favoritesByUser = {};

  @override
  Future<List<Property>> getFavorites(String userId) async {
    final ids = _favoritesByUser[userId] ?? {};
    return mockProperties.where((p) => ids.contains(p.id)).toList();
  }

  @override
  Future<void> addFavorite(String userId, String propertyId) async {
    _favoritesByUser.putIfAbsent(userId, () => {}).add(propertyId);
  }

  @override
  Future<void> removeFavorite(String userId, String propertyId) async {
    _favoritesByUser[userId]?.remove(propertyId);
  }

  @override
  Future<bool> isFavorite(String userId, String propertyId) async {
    return _favoritesByUser[userId]?.contains(propertyId) ?? false;
  }
}

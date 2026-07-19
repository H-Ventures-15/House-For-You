import '../models/property.dart';

/// Nécessite une session utilisateur (voir `AuthGuard`,
/// architecture-mvp.md section 1 et 7) — jamais appelé pour un invité.
abstract class FavoritesRepository {
  Future<List<Property>> getFavorites(String userId);

  Future<void> addFavorite(String userId, String propertyId);

  Future<void> removeFavorite(String userId, String propertyId);

  Future<bool> isFavorite(String userId, String propertyId);
}

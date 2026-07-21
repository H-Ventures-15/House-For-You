import '../models/property.dart';

/// Accessible sans compte (favoris locaux à l'appareil, voir DECISIONS.md) —
/// `userId` reste un identifiant de session mock (`mockSessionUserId`) tant
/// que l'authentification réelle et la synchronisation Supabase (étape 5/6)
/// n'existent pas.
abstract class FavoritesRepository {
  Future<List<Property>> getFavorites(String userId);

  Future<void> addFavorite(String userId, String propertyId);

  Future<void> removeFavorite(String userId, String propertyId);

  Future<bool> isFavorite(String userId, String propertyId);
}

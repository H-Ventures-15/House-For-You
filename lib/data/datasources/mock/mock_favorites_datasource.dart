import 'package:shared_preferences/shared_preferences.dart';

import '../../models/property.dart';
import '../../repositories/favorites_repository.dart';
import 'mock_property_data.dart';

/// Stockage local (`SharedPreferences`) plutôt qu'en mémoire — les favoris
/// doivent survivre à un redémarrage de l'app tant que l'authentification
/// réelle et la synchronisation Supabase (étape 5/6) n'existent pas (voir
/// DECISIONS.md). Remplacé par la table Supabase `favorites` à l'étape 10 ;
/// seule cette classe changera, l'interface `FavoritesRepository` et tout
/// ce qui la consomme restent inchangés.
class MockFavoritesDataSource implements FavoritesRepository {
  static const _keyPrefix = 'favorites_';

  Future<Set<String>> _readIds(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('$_keyPrefix$userId') ?? const []).toSet();
  }

  Future<void> _writeIds(String userId, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('$_keyPrefix$userId', ids.toList());
  }

  @override
  Future<List<Property>> getFavorites(String userId) async {
    final ids = await _readIds(userId);
    return mockProperties.where((p) => ids.contains(p.id)).toList();
  }

  @override
  Future<void> addFavorite(String userId, String propertyId) async {
    final ids = await _readIds(userId);
    if (ids.add(propertyId)) await _writeIds(userId, ids);
  }

  @override
  Future<void> removeFavorite(String userId, String propertyId) async {
    final ids = await _readIds(userId);
    if (ids.remove(propertyId)) await _writeIds(userId, ids);
  }

  @override
  Future<bool> isFavorite(String userId, String propertyId) async {
    return (await _readIds(userId)).contains(propertyId);
  }
}

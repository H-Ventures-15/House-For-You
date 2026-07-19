import '../models/property.dart';
import '../models/search_filters.dart';

/// Interface abstraite — l'UI et les providers ne connaissent que ce
/// contrat, jamais l'implémentation concrète (mock ou Supabase). Voir
/// architecture-mvp.md, section 1.
abstract class PropertyRepository {
  Future<List<Property>> getFeed();

  Future<List<Property>> search(SearchFilters filters);

  Future<Property?> getById(String id);

  Future<List<Property>> getByAgency(String agencyId);
}

import '../../models/property.dart';
import '../../models/search_filters.dart';
import '../../repositories/property_repository.dart';
import 'mock_property_data.dart';

/// Implémentation mock — active au MVP. Sera remplacée par
/// `SupabasePropertyDataSource` à l'étape 10 du plan sans changement côté UI
/// (voir architecture-mvp.md, section 1).
class MockPropertyDataSource implements PropertyRepository {
  static const _simulatedDelay = Duration(milliseconds: 300);

  @override
  Future<List<Property>> getFeed() async {
    await Future<void>.delayed(_simulatedDelay);
    final published = mockProperties.where((p) => p.isPublished).toList()
      ..sort(
        (a, b) => (b.publishedAt ?? b.createdAt).compareTo(
          a.publishedAt ?? a.createdAt,
        ),
      );
    return published;
  }

  @override
  Future<List<Property>> search(SearchFilters filters) async {
    await Future<void>.delayed(_simulatedDelay);
    return mockProperties
        .where((p) => p.isPublished && filters.matches(p))
        .toList();
  }

  @override
  Future<Property?> getById(String id) async {
    await Future<void>.delayed(_simulatedDelay);
    try {
      return mockProperties.firstWhere((p) => p.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<Property>> getByAgency(String agencyId) async {
    await Future<void>.delayed(_simulatedDelay);
    return mockProperties
        .where((p) => p.isPublished && p.agencyId == agencyId)
        .toList();
  }
}

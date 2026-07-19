import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/analytics_service.dart';
import '../datasources/mock/mock_agency_datasource.dart';
import '../datasources/mock/mock_favorites_datasource.dart';
import '../datasources/mock/mock_leads_datasource.dart';
import '../datasources/mock/mock_property_datasource.dart';
import '../repositories/agency_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/leads_repository.dart';
import '../repositories/property_repository.dart';

/// Point d'injection unique : pour brancher Supabase, ne changer que la
/// valeur retournée par ces providers (ex. `SupabasePropertyDataSource()`),
/// aucun autre fichier n'a besoin d'être modifié (voir architecture-mvp.md,
/// section 1 — MVP mode = mock, `DATA_SOURCE_MODE` dans .env).
final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return MockPropertyDataSource();
});

final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
  return MockAgencyDataSource();
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return MockFavoritesDataSource();
});

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return MockLeadsDataSource();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return MockAnalyticsService();
});

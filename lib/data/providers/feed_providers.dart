import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/agency.dart';
import '../models/property.dart';
import 'repository_providers.dart';

/// Biens publiés du feed Découvrir, triés par nouveauté (voir
/// `MockPropertyDataSource.getFeed`).
final feedPropertiesProvider = FutureProvider<List<Property>>((ref) {
  return ref.watch(propertyRepositoryProvider).getFeed();
});

/// Agences indexées par id — évite un appel réseau par carte pour le logo
/// agence affiché dans le feed et la fiche détail.
final agenciesByIdProvider = FutureProvider<Map<String, Agency>>((ref) async {
  final agencies = await ref.watch(agencyRepositoryProvider).getAll();
  return {for (final agency in agencies) agency.id: agency};
});

/// Un seul bien, pour la fiche détail (route `/property/:id`).
final propertyByIdProvider = FutureProvider.family<Property?, String>((
  ref,
  id,
) {
  return ref.watch(propertyRepositoryProvider).getById(id);
});

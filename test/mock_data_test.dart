import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/data/datasources/mock/mock_agency_data.dart';
import 'package:house_for_you/data/datasources/mock/mock_property_data.dart';
import 'package:house_for_you/data/models/property.dart';

void main() {
  group('Données mock', () {
    test('au moins 10 biens fictifs', () {
      expect(mockProperties.length, greaterThanOrEqualTo(10));
    });

    test('au moins 3 agences fictives', () {
      expect(mockAgencies.length, greaterThanOrEqualTo(3));
    });

    test('chaque bien référence une agence existante', () {
      final agencyIds = mockAgencies.map((a) => a.id).toSet();
      for (final property in mockProperties) {
        expect(
          agencyIds.contains(property.agencyId),
          isTrue,
          reason: '${property.id} référence une agence inconnue',
        );
      }
    });

    test('chaque bien publié a au moins une photo de couverture', () {
      for (final property in mockProperties.where((p) => p.isPublished)) {
        expect(
          property.coverPhotoUrl,
          isNotNull,
          reason: '${property.id} n\'a pas de photo de couverture',
        );
      }
    });

    test('toJson/fromJson round-trip conserve les champs clés', () {
      final original = mockProperties.first;
      final json = original.toJson();
      final restored = Property.fromJson(
        json,
        title: original.title,
        description: original.description,
      );
      expect(restored.id, original.id);
      expect(restored.price, original.price);
      expect(restored.city, original.city);
      expect(restored.status, original.status);
    });
  });
}

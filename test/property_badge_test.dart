import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/data/datasources/mock/mock_property_data.dart';
import 'package:house_for_you/data/models/property.dart';
import 'package:house_for_you/data/models/property_badge.dart';

Property _baseProperty({
  bool isExclusive = false,
  bool isFeatured = false,
  bool hasVirtualTour = false,
  num? previousPrice,
  num price = 200000,
  DateTime? publishedAt,
}) {
  return Property(
    id: 'test-prop',
    transactionType: TransactionType.sale,
    propertyType: PropertyType.apartment,
    title: 'Test',
    description: 'Test',
    price: price,
    surface: 80,
    bedrooms: 2,
    isExclusive: isExclusive,
    isFeatured: isFeatured,
    hasVirtualTour: hasVirtualTour,
    previousPrice: previousPrice,
    postalCode: '1000',
    city: 'Bruxelles',
    status: PropertyStatus.published,
    publishedAt: publishedAt,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('propertyBadges', () {
    final reference = DateTime(2026, 7, 21);

    test('aucun champ actif -> aucun badge', () {
      final property = _baseProperty();
      expect(propertyBadges(property, now: reference), isEmpty);
    });

    test('isExclusive -> badge Exclusivité', () {
      final property = _baseProperty(isExclusive: true);
      expect(
        propertyBadges(property, now: reference),
        contains(PropertyBadge.exclusive),
      );
    });

    test('isFeatured -> badge Coup de cœur', () {
      final property = _baseProperty(isFeatured: true);
      expect(
        propertyBadges(property, now: reference),
        contains(PropertyBadge.featured),
      );
    });

    test('previousPrice > price -> badge Prix réduit', () {
      final property = _baseProperty(price: 200000, previousPrice: 230000);
      expect(
        propertyBadges(property, now: reference),
        contains(PropertyBadge.priceReduced),
      );
    });

    test('previousPrice <= price -> pas de badge Prix réduit', () {
      final property = _baseProperty(price: 200000, previousPrice: 190000);
      expect(
        propertyBadges(property, now: reference),
        isNot(contains(PropertyBadge.priceReduced)),
      );
    });

    test('hasVirtualTour -> badge Visite virtuelle', () {
      final property = _baseProperty(hasVirtualTour: true);
      expect(
        propertyBadges(property, now: reference),
        contains(PropertyBadge.virtualTour),
      );
    });

    test('publié il y a moins de 14 jours -> badge Nouveau', () {
      final property = _baseProperty(
        publishedAt: reference.subtract(const Duration(days: 5)),
      );
      expect(
        propertyBadges(property, now: reference),
        contains(PropertyBadge.newListing),
      );
    });

    test('publié il y a plus de 14 jours -> pas de badge Nouveau', () {
      final property = _baseProperty(
        publishedAt: reference.subtract(const Duration(days: 20)),
      );
      expect(
        propertyBadges(property, now: reference),
        isNot(contains(PropertyBadge.newListing)),
      );
    });

    test('ordre de priorité : exclusivité avant coup de cœur avant nouveau',
        () {
      final property = _baseProperty(
        isExclusive: true,
        isFeatured: true,
        publishedAt: reference.subtract(const Duration(days: 1)),
      );
      final badges = propertyBadges(property, now: reference);
      expect(badges.indexOf(PropertyBadge.exclusive), 0);
      expect(
        badges.indexOf(PropertyBadge.exclusive) <
            badges.indexOf(PropertyBadge.featured),
        isTrue,
      );
    });
  });

  group('Property.toJson/fromJson round-trip des champs badges', () {
    test('conserve isExclusive/isFeatured/hasVirtualTour/previousPrice', () {
      final original = _baseProperty(
        isExclusive: true,
        isFeatured: true,
        hasVirtualTour: true,
        previousPrice: 250000,
        price: 220000,
      );
      final restored = Property.fromJson(
        original.toJson(),
        title: original.title,
        description: original.description,
      );
      expect(restored.isExclusive, isTrue);
      expect(restored.isFeatured, isTrue);
      expect(restored.hasVirtualTour, isTrue);
      expect(restored.previousPrice, 250000);
    });
  });

  group('Données mock — badges', () {
    test('au moins un bien mock porte chaque type de champ badge', () {
      expect(mockProperties.any((p) => p.isExclusive), isTrue);
      expect(mockProperties.any((p) => p.isFeatured), isTrue);
      expect(mockProperties.any((p) => p.hasVirtualTour), isTrue);
      expect(mockProperties.any((p) => p.previousPrice != null), isTrue);
    });
  });

  group('propertyBadgeLabel / propertyBadgeIcon', () {
    test('chaque badge a un libellé non vide', () {
      for (final badge in PropertyBadge.values) {
        expect(propertyBadgeLabel(badge), isNotEmpty);
      }
    });
  });
}

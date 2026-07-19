import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/core/widgets/property_card.dart';
import 'package:house_for_you/data/datasources/mock/mock_property_data.dart';
import 'package:network_image_mock/network_image_mock.dart';

/// Vérifie la séparation stricte des zones de gestes sur la carte feed :
/// le média (haut) répond au double tap (favori), le bloc texte (bas)
/// répond au tap simple (ouvrir la fiche) — jamais l'inverse.
void main() {
  final property = mockProperties.firstWhere((p) => p.id == 'prop-1');

  Widget buildCard({
    required VoidCallback onTap,
    required bool Function() onToggleFavorite,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PropertyCard.feed(
          property: property,
          isFavorite: false,
          onTap: onTap,
          onToggleFavorite: onToggleFavorite,
          onShare: () {},
        ),
      ),
    );
  }

  testWidgets('tap sur le bloc texte (bas) ouvre la fiche', (tester) async {
    await mockNetworkImagesFor(() async {
      var tapped = false;
      await tester.pumpWidget(
        buildCard(onTap: () => tapped = true, onToggleFavorite: () => true),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(400, 580));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  testWidgets('tap sur le média (haut) n\'ouvre pas la fiche', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      var tapped = false;
      await tester.pumpWidget(
        buildCard(onTap: () => tapped = true, onToggleFavorite: () => true),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(400, 120));
      // Laisse le délai de détection du double tap s'écouler (un timer
      // reste sinon en attente et fait échouer le test).
      await tester.pump(kDoubleTapTimeout);

      expect(tapped, isFalse);
    });
  });

  testWidgets('double tap sur le média bascule le favori avec animation', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      var toggleCount = 0;
      await tester.pumpWidget(
        buildCard(
          onTap: () {},
          onToggleFavorite: () {
            toggleCount++;
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsNothing);

      const position = Offset(400, 120);
      await tester.tapAt(position);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(position);
      await tester.pump();

      expect(toggleCount, 1);
      // Le cœur d'animation du double tap apparaît.
      expect(find.byIcon(Icons.favorite), findsWidgets);
      // Laisse l'animation du cœur (700ms) se terminer avant la fin du test.
      await tester.pumpAndSettle();
    });
  });

  testWidgets('double tap sur le bloc texte ne déclenche pas le favori', (
    tester,
  ) async {
    await mockNetworkImagesFor(() async {
      var toggleCount = 0;
      await tester.pumpWidget(
        buildCard(
          onTap: () {},
          onToggleFavorite: () {
            toggleCount++;
            return true;
          },
        ),
      );
      await tester.pumpAndSettle();

      const position = Offset(400, 580);
      await tester.tapAt(position);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(position);
      await tester.pump();

      expect(toggleCount, 0);
    });
  });
}

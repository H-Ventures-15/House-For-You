import 'package:flutter/gestures.dart'
    show kDoubleTapTimeout, kLongPressTimeout, kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/core/widgets/property_card.dart';
import 'package:house_for_you/data/datasources/mock/mock_property_data.dart';
import 'package:network_image_mock/network_image_mock.dart';

final _longPressDuration = kLongPressTimeout + kPressTimeout;

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

  testWidgets(
    'appui long sur le média masque le chrome puis le restaure au relâchement',
    (tester) async {
      await mockNetworkImagesFor(() async {
        var startCalls = 0;
        var endCalls = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PropertyCard.feed(
                property: property,
                isFavorite: false,
                onTap: () {},
                onToggleFavorite: () => true,
                onShare: () {},
                onLongPressStart: () => startCalls++,
                onLongPressEnd: () => endCalls++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final chromeFinder = find.byKey(const Key('feed-card-chrome'));
        expect(tester.widget<AnimatedOpacity>(chromeFinder).opacity, 1.0);

        final gesture = await tester.startGesture(const Offset(400, 120));
        await tester.pump(_longPressDuration);

        expect(startCalls, 1);
        expect(endCalls, 0);
        expect(tester.widget<AnimatedOpacity>(chromeFinder).opacity, 0.0);

        await gesture.up();
        await tester.pump();

        expect(endCalls, 1);
        expect(tester.widget<AnimatedOpacity>(chromeFinder).opacity, 1.0);
        // Laisse le fondu de réapparition (180ms) se terminer.
        await tester.pumpAndSettle();
      });
    },
  );

  testWidgets(
    'un appui long ne déclenche ni le favori (double tap) ni l\'ouverture '
    'de la fiche',
    (tester) async {
      await mockNetworkImagesFor(() async {
        var tapped = false;
        var toggleCount = 0;
        await tester.pumpWidget(
          buildCard(
            onTap: () => tapped = true,
            onToggleFavorite: () {
              toggleCount++;
              return true;
            },
          ),
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(const Offset(400, 120));
        await tester.pump(_longPressDuration);
        await gesture.up();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(tapped, isFalse);
        expect(toggleCount, 0);
      });
    },
  );

  testWidgets(
    'le bouton favori et la zone d\'ouverture de fiche portent des labels '
    'sémantiques',
    (tester) async {
      final handle = tester.ensureSemantics();
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          buildCard(onTap: () {}, onToggleFavorite: () => true),
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Ajouter aux favoris'), findsOneWidget);
        expect(find.bySemanticsLabel('Partager ce bien'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp(r'^Ouvrir la fiche du bien')),
          findsOneWidget,
        );
      });
      handle.dispose();
    },
  );
}
